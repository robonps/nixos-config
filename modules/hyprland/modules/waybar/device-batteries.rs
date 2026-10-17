//! Event-driven UPower peripheral battery indicator. No polling or subprocesses.
use std::ffi::{CStr, c_char, c_int, c_uint, c_ulong, c_void};
use std::io::{self, Write};
use std::ptr;

type Object = *mut c_void;
type Callback = Option<unsafe extern "C" fn()>;

#[repr(C)]
struct PtrArray {
    data: *mut Object,
    len: c_uint,
}

#[link(name = "upower-glib")]
unsafe extern "C" {
    fn up_client_new_full(cancel: Object, error: Object) -> Object;
    fn up_client_get_devices2(client: Object) -> *mut PtrArray;
    fn up_device_get_object_path(device: Object) -> *const c_char;
}
#[link(name = "gobject-2.0")]
unsafe extern "C" {
    fn g_object_ref(object: Object) -> Object;
    fn g_object_unref(object: Object);
    fn g_object_get(object: Object, property: *const c_char, ...);
    fn g_signal_connect_data(
        object: Object,
        signal: *const c_char,
        callback: Callback,
        data: Object,
        destroy: Object,
        flags: c_uint,
    ) -> c_ulong;
    fn g_signal_handler_disconnect(object: Object, handler: c_ulong);
}
#[link(name = "glib-2.0")]
unsafe extern "C" {
    fn g_main_loop_new(context: Object, running: c_int) -> Object;
    fn g_main_loop_run(main_loop: Object);
    fn g_main_loop_unref(main_loop: Object);
    fn g_ptr_array_unref(array: *mut PtrArray);
    fn g_free(memory: Object);
}
#[link(name = "gio-2.0")]
unsafe extern "C" {
    fn g_bus_watch_name(
        bus: c_int,
        name: *const c_char,
        flags: c_uint,
        appeared: Option<unsafe extern "C" fn(Object, *const c_char, *const c_char, Object)>,
        vanished: Option<unsafe extern "C" fn(Object, *const c_char, Object)>,
        data: Object,
        destroy: Object,
    ) -> c_uint;
    fn g_bus_unwatch_name(id: c_uint);
}

struct WatchedDevice {
    object: Object,
    handler: c_ulong,
    path: String,
}
impl Drop for WatchedDevice {
    fn drop(&mut self) {
        // Each device owns a reference and its handler. Disconnect before freeing.
        unsafe {
            g_signal_handler_disconnect(self.object, self.handler);
            g_object_unref(self.object);
        }
    }
}

#[derive(Default)]
struct State {
    client: Object,
    client_handlers: Vec<c_ulong>,
    devices: Vec<WatchedDevice>,
    previous: Option<String>,
}
impl State {
    fn clear(&mut self) {
        self.devices.clear();
        if !self.client.is_null() {
            unsafe {
                for handler in self.client_handlers.drain(..) {
                    g_signal_handler_disconnect(self.client, handler);
                }
                g_object_unref(self.client);
            }
            self.client = ptr::null_mut();
        }
    }

    fn emit(&mut self) {
        let mut labels = Vec::new();
        let mut tooltips = Vec::new();
        for device in &self.devices {
            let battery = unsafe { Battery::read(device.object) };
            if let Some((label, tooltip)) = battery.display() {
                labels.push(label);
                tooltips.push(tooltip);
            }
        }
        let output = format!(
            "{{\"text\":{},\"tooltip\":{}}}",
            json_string(&labels.join("  ")),
            json_string(&tooltips.join("\n"))
        );
        if self.previous.as_ref() != Some(&output) {
            let mut stdout = io::stdout().lock();
            if writeln!(stdout, "{output}")
                .and_then(|_| stdout.flush())
                .is_err()
            {
                // Waybar closed our output pipe; terminate rather than lingering.
                std::process::exit(0);
            }
            self.previous = Some(output);
        }
    }
}

#[derive(Default)]
struct Battery {
    kind: c_uint,
    present: c_int,
    power_supply: c_int,
    battery_missing: bool,
    percentage: f64,
    level: c_uint,
    state: c_uint,
    model: String,
}
impl Battery {
    unsafe fn read(device: Object) -> Self {
        let mut result = Self::default();
        let mut model: *mut c_char = ptr::null_mut();
        let mut icon_name: *mut c_char = ptr::null_mut();
        // GObject properties have stable types in UPower: enums are guint,
        // booleans gboolean, percentage double, and model an allocated string.
        unsafe {
            g_object_get(
                device,
                c"kind".as_ptr(),
                &mut result.kind,
                c"is-present".as_ptr(),
                &mut result.present,
                c"power-supply".as_ptr(),
                &mut result.power_supply,
                c"percentage".as_ptr(),
                &mut result.percentage,
                c"battery-level".as_ptr(),
                &mut result.level,
                c"state".as_ptr(),
                &mut result.state,
                c"model".as_ptr(),
                &mut model,
                c"icon-name".as_ptr(),
                &mut icon_name,
                ptr::null::<c_char>(),
            );
            if !model.is_null() {
                result.model = CStr::from_ptr(model).to_string_lossy().into_owned();
                g_free(model.cast());
            }
            if !icon_name.is_null() {
                result.battery_missing = CStr::from_ptr(icon_name) == c"battery-missing-symbolic";
                g_free(icon_name.cast());
            }
        }
        result
    }

    fn display(&self) -> Option<(String, String)> {
        // Receiver-backed mice remain present with a cached percentage when off.
        // UPower marks those readings with its missing-battery icon instead.
        if self.present == 0
            || self.battery_missing
            || self.power_supply != 0
            || matches!(self.kind, 1 | 3)
        {
            return None;
        }
        // UPower BatteryLevel: UNKNOWN=0, NONE=1, then coarse charge levels.
        let charge = match self.level {
            1 if self.percentage.is_finite() && (0.0..=100.0).contains(&self.percentage) => {
                format!("{:.0}%", self.percentage)
            }
            3 => "Low".into(),
            4 => "Critical".into(),
            6 => "Normal".into(),
            7 => "High".into(),
            8 => "Full".into(),
            _ => return None,
        };
        let (icon, kind) = match self.kind {
            5 => ("󰍽", "Mouse"),
            6 => ("󰌌", "Keyboard"),
            8 => ("󰏲", "Phone"),
            10 => ("󰓶", "Tablet"),
            12 => ("󰊴", "Controller"),
            19 => ("󰋋", "Headphones"),
            17 => ("󰋎", "Headset"),
            18 => ("󰓃", "Speakers"),
            14 => ("󰟸", "Touchpad"),
            13 => ("󰏪", "Pen"),
            _ => ("󰁹", "Device"),
        };
        let state = match self.state {
            1 => "charging",
            2 => "discharging",
            3 => "empty",
            4 => "fully charged",
            5 => "pending charge",
            6 => "pending discharge",
            _ => "unknown",
        };
        let name = if self.model.is_empty() {
            kind
        } else {
            &self.model
        };
        let charging = if self.state == 1 { " 󰂄" } else { "" };
        Some((
            format!("{icon} {charge}{charging}"),
            format!("{name}: {charge} ({state})"),
        ))
    }
}

fn json_string(value: &str) -> String {
    let mut result = String::from("\"");
    for ch in value.chars() {
        match ch {
            '"' => result.push_str("\\\""),
            '\\' => result.push_str("\\\\"),
            '\n' => result.push_str("\\n"),
            '\r' => result.push_str("\\r"),
            '\t' => result.push_str("\\t"),
            ch if ch < ' ' => result.push_str(&format!("\\u{:04x}", ch as u32)),
            ch => result.push(ch),
        }
    }
    result.push('"');
    result
}

// All callbacks run on GLib's single main context. State stays boxed at the same
// address until all signal handlers and the bus watch have been disconnected.
unsafe extern "C" fn changed(_device: Object, _property: Object, data: Object) {
    unsafe { (&mut *data.cast::<State>()).emit() };
}

unsafe extern "C" fn added(_client: Object, device: Object, data: Object) {
    unsafe {
        let state = &mut *data.cast::<State>();
        let path = up_device_get_object_path(device);
        if path.is_null() {
            return;
        }
        let path = CStr::from_ptr(path).to_string_lossy().into_owned();
        if state.devices.iter().any(|d| d.path == path) {
            return;
        }
        let handler = g_signal_connect_data(
            device,
            c"notify".as_ptr(),
            Some(std::mem::transmute::<
                unsafe extern "C" fn(Object, Object, Object),
                unsafe extern "C" fn(),
            >(changed)),
            data,
            ptr::null_mut(),
            0,
        );
        state.devices.push(WatchedDevice {
            object: g_object_ref(device),
            handler,
            path,
        });
        state.devices.sort_by(|a, b| a.path.cmp(&b.path));
        state.emit();
    }
}

unsafe extern "C" fn removed(_client: Object, path: *const c_char, data: Object) {
    unsafe {
        if path.is_null() {
            return;
        }
        let state = &mut *data.cast::<State>();
        let path = CStr::from_ptr(path).to_string_lossy();
        state.devices.retain(|device| device.path != path);
        state.emit();
    }
}

unsafe extern "C" fn appeared(
    _bus: Object,
    _name: *const c_char,
    _owner: *const c_char,
    data: Object,
) {
    unsafe {
        // Do not hold a mutable State reference across library calls: synchronous
        // D-Bus calls can dispatch callbacks through GLib's main context.
        (&mut *data.cast::<State>()).clear();
        let client = up_client_new_full(ptr::null_mut(), ptr::null_mut());
        if client.is_null() {
            return;
        }
        let add_handler = g_signal_connect_data(
            client,
            c"device-added".as_ptr(),
            Some(std::mem::transmute::<
                unsafe extern "C" fn(Object, Object, Object),
                unsafe extern "C" fn(),
            >(added)),
            data,
            ptr::null_mut(),
            0,
        );
        let remove_handler = g_signal_connect_data(
            client,
            c"device-removed".as_ptr(),
            Some(std::mem::transmute::<
                unsafe extern "C" fn(Object, *const c_char, Object),
                unsafe extern "C" fn(),
            >(removed)),
            data,
            ptr::null_mut(),
            0,
        );
        (&mut *data.cast::<State>()).client = client;
        (&mut *data.cast::<State>()).client_handlers = vec![add_handler, remove_handler];
        let devices = up_client_get_devices2(client);
        if !devices.is_null() {
            for i in 0..(*devices).len as usize {
                added(client, *(*devices).data.add(i), data);
            }
            g_ptr_array_unref(devices);
        }
        (&mut *data.cast::<State>()).emit();
    }
}

unsafe extern "C" fn vanished(_bus: Object, _name: *const c_char, data: Object) {
    unsafe {
        let state = &mut *data.cast::<State>();
        state.clear();
        state.emit();
    }
}

fn main() {
    let mut state = Box::<State>::default();
    state.emit();
    unsafe {
        let data = (&mut *state as *mut State).cast();
        let main_loop = g_main_loop_new(ptr::null_mut(), 0);
        // G_BUS_TYPE_SYSTEM=1, G_BUS_NAME_WATCHER_FLAGS_AUTO_START=1.
        // Activate UPower if nothing else has requested it since login; otherwise
        // watching alone can leave the indicator empty indefinitely.
        let watch = g_bus_watch_name(
            1,
            c"org.freedesktop.UPower".as_ptr(),
            1,
            Some(appeared),
            Some(vanished),
            data,
            ptr::null_mut(),
        );
        g_main_loop_run(main_loop);
        g_bus_unwatch_name(watch);
        state.clear();
        g_main_loop_unref(main_loop);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mouse() -> Battery {
        Battery {
            kind: 5,
            present: 1,
            percentage: 72.0,
            level: 1,
            state: 2,
            model: "Wireless Mouse".into(),
            ..Battery::default()
        }
    }

    #[test]
    fn icons_charge_and_charging() {
        assert_eq!(
            mouse().display(),
            Some(("󰍽 72%".into(), "Wireless Mouse: 72% (discharging)".into()))
        );
        let headphones = Battery {
            kind: 19,
            state: 1,
            model: "".into(),
            ..mouse()
        };
        assert_eq!(headphones.display().unwrap().0, "󰋋 72% 󰂄");
    }

    #[test]
    fn absent_system_and_unknown_batteries_are_hidden() {
        assert!(
            Battery {
                present: 0,
                ..mouse()
            }
            .display()
            .is_none()
        );
        assert!(
            Battery {
                power_supply: 1,
                ..mouse()
            }
            .display()
            .is_none()
        );
        assert!(
            Battery {
                level: 0,
                ..mouse()
            }
            .display()
            .is_none()
        );
        assert!(
            Battery {
                percentage: f64::NAN,
                ..mouse()
            }
            .display()
            .is_none()
        );
        assert_eq!(
            Battery {
                percentage: 0.0,
                ..mouse()
            }
            .display()
            .unwrap()
            .0,
            "󰍽 0%"
        );
        assert_eq!(
            Battery {
                level: 3,
                ..mouse()
            }
            .display()
            .unwrap()
            .0,
            "󰍽 Low"
        );
    }

    #[test]
    fn json_escapes_device_names_and_tooltips() {
        assert_eq!(
            json_string("A\"\\\n\t\u{1}󰍽"),
            "\"A\\\"\\\\\\n\\t\\u0001󰍽\""
        );
    }

    #[test]
    fn switched_off_mouse_with_cached_charge_is_hidden() {
        let offline = Battery {
            battery_missing: true,
            state: 0,
            ..mouse()
        };
        assert!(offline.display().is_none());
        let online = Battery {
            battery_missing: false,
            ..offline
        };
        assert!(online.display().is_some());
    }
}
