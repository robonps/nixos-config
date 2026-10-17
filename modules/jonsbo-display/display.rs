use std::fs::{self, File, OpenOptions};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::ExitCode;
use std::thread;
use std::time::{Duration, Instant};

const REPORT_DESCRIPTOR: &[u8] = &[
    0x06, 0x00, 0xff, 0x09, 0x01, 0xa1, 0x01, 0x09, 0x02, 0x15, 0x00, 0x26, 0x00,
    0xff, 0x75, 0x08, 0x95, 0x40, 0x81, 0x06, 0x09, 0x02, 0x15, 0x00, 0x26, 0x00,
    0xff, 0x75, 0x08, 0x95, 0x40, 0x91, 0x06, 0xc0,
];
const REFRESH: Duration = Duration::from_millis(200);
const SAMPLE_INTERVAL: Duration = Duration::from_secs(2);

fn error(message: &str) -> io::Error {
    io::Error::other(message)
}

fn display_device(root: &Path) -> io::Result<PathBuf> {
    let mut found = None;
    for entry in fs::read_dir(root)? {
        let entry = entry?;
        let path = entry.path().join("device");
        let Ok(info) = fs::read_to_string(path.join("uevent")) else {
            continue;
        };
        if !info.lines().any(|line| line == "HID_ID=0003:00005131:00002007") {
            continue;
        }
        if fs::read(path.join("report_descriptor"))? != REPORT_DESCRIPTOR {
            return Err(error("5131:2007 has an unexpected HID descriptor"));
        }
        if found.replace(Path::new("/dev").join(entry.file_name())).is_some() {
            return Err(error("more than one matching display; refusing to choose"));
        }
    }
    found.ok_or_else(|| error("Jonsbo display not connected"))
}

fn cpu_sensor(root: &Path) -> io::Result<PathBuf> {
    for entry in fs::read_dir(root)? {
        let path = entry?.path();
        if fs::read_to_string(path.join("name")).unwrap_or_default().trim() != "k10temp" {
            continue;
        }
        // Prefer the explicitly labelled CPU control temperature over CCD sensors.
        for sensor in fs::read_dir(&path)? {
            let sensor = sensor?.path();
            let name = sensor.file_name().unwrap().to_string_lossy();
            if name.starts_with("temp") && name.ends_with("_label")
                && fs::read_to_string(&sensor)?.trim() == "Tctl"
            {
                return Ok(path.join(name.replace("_label", "_input")));
            }
        }
        let fallback = path.join("temp1_input");
        if fallback.is_file() {
            return Ok(fallback);
        }
    }
    Err(error("AMD k10temp CPU sensor not found"))
}

fn temperature(sensor: &Path, buffer: &mut String) -> io::Result<u8> {
    buffer.clear();
    use std::io::Read;
    File::open(sensor)?.read_to_string(buffer)?;
    let millidegrees: i64 = buffer.trim().parse().map_err(|_| error("invalid CPU temperature"))?;
    Ok(((millidegrees.clamp(0, 99_000) + 500) / 1000) as u8)
}

fn run() -> io::Result<()> {
    let args: Vec<_> = std::env::args().skip(1).collect();
    let check = args == ["--check"];
    if !args.is_empty() && !check {
        return Err(error("usage: jonsbo-display [--check]"));
    }
    let device = display_device(Path::new("/sys/class/hidraw"))?;
    let sensor = cpu_sensor(Path::new("/sys/class/hwmon"))?;
    let mut buffer = String::with_capacity(32);
    let mut value = temperature(&sensor, &mut buffer)?;
    eprintln!("{}: CPU {} °C from {}", device.display(), value, sensor.display());
    if check {
        return Ok(());
    }
    let mut display = OpenOptions::new().write(true).open(device)?;
    // Linux report-number prefix + the verified 64-byte Jonsbo payload.
    let mut report = [0_u8; 65];
    report[2] = 1;
    report[3] = 2;
    let mut next_sample = Instant::now() + SAMPLE_INTERVAL;
    loop {
        let started = Instant::now();
        if started >= next_sample {
            value = temperature(&sensor, &mut buffer)?;
            next_sample = started + SAMPLE_INTERVAL;
        }
        report[4] = value;
        // One USB report per write. Never split a short write into another report.
        if display.write(&report)? != report.len() {
            return Err(error("incomplete HID report write"));
        }
        thread::sleep(REFRESH.saturating_sub(started.elapsed()));
    }
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            eprintln!("jonsbo-display: {err}");
            ExitCode::FAILURE
        }
    }
}
