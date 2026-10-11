"""Run with python3 -m unittest discover -s modules/hyprland/modules/scripts."""

import copy
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("manager", Path(__file__).with_name("wallpaper-manager.py"))
manager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(manager)


def output(name, x, y, w, h, scale=1):
    return dict(name=name, x=x, y=y, w=w, h=h, scale=scale)


class GeometryTests(unittest.TestCase):
    def test_fastboi_panorama_and_shared_edges(self):
        outputs = [output("left", 0, 130, 1920, 1080), output("center", 1920, 0, 2560, 1440),
                   output("right", 4480, 130, 1920, 1080)]
        self.assertEqual(manager.bounds(outputs), (0, 0, 6400, 1440))
        # Reconstruct mpv's video origin from the scale/pan options; every output
        # must see the same desktop canvas, including the asymmetric vertical offset.
        for monitor in outputs:
            transform = manager.video_transform(monitor, outputs, 1920, 1080)
            scaled_w = 1920 * transform["video-scale-x"]
            scaled_h = 1080 * transform["video-scale-y"]
            origin_x = (monitor["w"] - scaled_w) / 2 + transform["video-pan-x"] * scaled_w
            origin_y = (monitor["h"] - scaled_h) / 2 + transform["video-pan-y"] * scaled_h
            self.assertAlmostEqual(origin_x + monitor["x"], 0)
            self.assertAlmostEqual(origin_y + monitor["y"], -1080)

    def test_negative_positions_and_scaled_monitor(self):
        outputs = [output("a", -800, -100, 800, 600), output("b", 0, 0, 800, 600, 2)]
        self.assertEqual(manager.bounds(outputs), (-800, -100, 1600, 700))
        options = manager.video_transform(outputs[1], outputs, 1600, 700)
        self.assertEqual(options["video-scale-x"], 2)
        self.assertAlmostEqual(options["video-pan-x"], -0.25)

    def test_fractional_scale_uses_the_players_framebuffer(self):
        outputs = [output("a", 0, 0, 800, 600), output("b", 800, 0, 800, 600, 1.5)]
        options = manager.video_transform(outputs[1], outputs, 1600, 600, (1600, 1200))
        self.assertEqual(options["video-scale-x"], 2)
        self.assertEqual(options["video-scale-y"], 2)


class StateTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        self.cache_patch = patch.object(manager, "CACHE", self.root / "cache")
        self.cache_patch.start()
        self.outputs = [output("left", 0, 0, 10, 10), output("right", 10, 0, 10, 10)]
        self.monitor_patch = patch.object(manager, "monitors", return_value=self.outputs)
        self.monitor_patch.start()
        self.controller = manager.Controller()
        self.renderer = patch.object(self.controller, "reconcile")
        self.reconcile = self.renderer.start()
        self.image = self.root / "image with 'quotes' # $dollars.png"
        self.image.write_bytes(b"test image")

    def tearDown(self):
        self.renderer.stop()
        self.monitor_patch.stop()
        self.cache_patch.stop()
        self.directory.cleanup()

    def test_per_monitor_preserves_other_choice_and_remembers_global_layout(self):
        self.controller.apply(str(self.image), "span", "all")
        before = copy.deepcopy(self.controller.state["assignments"]["right"])
        second = self.root / "second.png"
        second.write_bytes(b"second")
        self.controller.apply(str(second), "repeat", "left")
        self.assertEqual(self.controller.state["assignments"]["right"], before)
        self.controller.apply(str(self.image), None, None)
        self.assertEqual(self.controller.state["last"]["layout"], "repeat")
        self.assertEqual(self.controller.state["last"]["target"], "all")
        saved = json.loads((manager.CACHE / "state.json").read_text())
        self.assertEqual(saved["current"], str(self.image))

    def test_layout_is_shared_across_files_but_monitor_selection_is_not_remembered(self):
        self.controller.apply(str(self.image), "repeat", "left")
        second = self.root / "second.png"
        second.write_bytes(b"second")
        result = self.controller.apply(str(second), None, None)
        self.assertEqual(result["target"], "all")
        self.controller.apply(str(second), "span", "all")
        self.assertEqual(self.controller.apply(str(self.image), None, None)["layout"], "span")

    def test_old_per_file_screen_preferences_are_ignored_and_removed(self):
        self.controller.state["preferences"] = {str(self.image): dict(layout="span", target="missing")}
        self.controller.state["last"] = dict(layout="repeat", target="left")
        result = self.controller.apply(str(self.image), None, None)
        self.assertEqual((result["layout"], result["target"]), ("repeat", "all"))
        self.assertNotIn("preferences", self.controller.state)

    def test_failure_rolls_back_without_persisting_new_selection(self):
        self.controller.apply(str(self.image), "repeat", "all")
        before = copy.deepcopy(self.controller.state)
        saved = (manager.CACHE / "state.json").read_bytes()
        self.reconcile.side_effect = [ValueError("decoder failed"), None]
        with self.assertRaisesRegex(ValueError, "decoder failed"):
            self.controller.apply(str(self.image), "span", "all")
        self.assertEqual(self.controller.state, before)
        self.assertEqual((manager.CACHE / "state.json").read_bytes(), saved)
        self.assertEqual(self.reconcile.call_args.args[0], before)

    def test_single_monitor_span_and_disconnected_target_fail_before_rendering(self):
        with self.assertRaisesRegex(ValueError, "at least two"):
            self.controller.apply(str(self.image), "span", "left")
        with self.assertRaisesRegex(ValueError, "disconnected"):
            self.controller.apply(str(self.image), "repeat", "missing")
        self.reconcile.assert_not_called()

    def test_theme_key_is_independent_of_layout_and_monitor(self):
        first = self.controller.apply(str(self.image), "repeat", "left")
        second = self.controller.apply(str(self.image), "span", "all")
        self.assertEqual(first["theme_key"], second["theme_key"])

    def test_random_selection_supports_an_arbitrary_directory(self):
        result = self.controller.apply(str(self.root), "repeat", "all")
        self.assertEqual(result["path"], str(self.image))

    def test_symlink_library_is_scanned_without_directory_cycles(self):
        library = self.root / "library"
        library.mkdir()
        (library / "linked.png").symlink_to(self.image)
        (library / "loop").symlink_to(library, target_is_directory=True)
        self.assertEqual(list(manager.library_files(library)), [library / "linked.png"])

    def test_scan_lists_media_without_decoding_images_or_videos(self):
        library = self.root / "Pictures/Wallpapers"
        library.mkdir(parents=True)
        for name in ["large.png", "video.mp4"]:
            (library / name).write_bytes(b"not decoded while listing")
        with patch.object(manager.Path, "home", return_value=self.root), \
                patch.object(manager, "poster", side_effect=AssertionError("scan decoded video")), \
                patch.object(manager, "thumbnail", side_effect=AssertionError("scan generated preview")):
            files = manager.scan()["files"]
        self.assertEqual(len(files), 2)
        self.assertTrue(all(not f["thumbnailReady"] for f in files))
        self.assertTrue(all(f["thumbnail"].endswith("-360-v1.jpg") for f in files))


@unittest.skipUnless(shutil.which("magick") and shutil.which("ffmpeg"), "ImageMagick and FFmpeg required")
class MediaTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        self.cache_patch = patch.object(manager, "CACHE", self.root / "cache")
        self.cache_patch.start()

    def tearDown(self):
        self.cache_patch.stop()
        self.directory.cleanup()

    def test_image_span_uses_correct_section_and_preserves_gif_animation(self):
        source = self.root / "panorama.png"
        manager.run("magick", "-size", "10x10", "xc:red", "-size", "10x10", "xc:blue", "+append", str(source))
        outputs = [output("left", 0, 0, 10, 10), output("right", 10, 0, 10, 10)]
        left = manager.image_crop(source, outputs[0], outputs)
        right = manager.image_crop(source, outputs[1], outputs)
        self.assertEqual(manager.run("magick", str(left), "-format", "%[pixel:p{5,5}]", "info:"), "srgb(255,0,0)")
        self.assertEqual(manager.run("magick", str(right), "-format", "%[pixel:p{5,5}]", "info:"), "srgb(0,0,255)")
        gif = self.root / "animated.gif"
        manager.run("magick", "-delay", "10", str(source), str(source), "-loop", "0", str(gif))
        crop = manager.image_crop(gif, outputs[0], outputs)
        self.assertEqual(len(manager.run("magick", "identify", str(crop)).splitlines()), 2)

    def test_video_frame_cache_and_changed_source_invalidation(self):
        video = self.root / "sample # 'quoted'.MP4"
        manager.run("ffmpeg", "-nostdin", "-v", "error", "-f", "lavfi", "-i", "color=c=green:s=64x32:d=0.2",
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-y", str(video))
        frame = manager.poster(video)
        self.assertTrue(frame.is_file())
        modified = frame.stat().st_mtime_ns
        self.assertEqual(manager.poster(video), frame)
        self.assertEqual(frame.stat().st_mtime_ns, modified)
        video.touch()
        self.assertNotEqual(manager.poster(video), frame)

    def test_image_thumbnail_is_small_cached_and_invalidated_on_source_change(self):
        image = self.root / "large.png"
        manager.run("magick", "-size", "4000x2000", "gradient:red-blue", str(image))
        preview = manager.thumbnail(image)
        self.assertEqual(manager.run("magick", "identify", "-format", "%wx%h", str(preview)), "360x360")
        with patch.object(manager, "run", side_effect=AssertionError("cached preview was decoded again")):
            self.assertEqual(manager.thumbnail(image), preview)
        image.touch()
        self.assertNotEqual(manager.thumbnail(image), preview)

    def test_video_preview_does_not_generate_the_larger_theme_frame(self):
        video = self.root / "preview.webm"
        manager.run("ffmpeg", "-nostdin", "-v", "error", "-f", "lavfi", "-i", "color=c=green:s=64x32:d=0.2",
                    "-c:v", "libvpx", "-y", str(video))
        preview = manager.thumbnail(video)
        self.assertEqual(manager.run("magick", "identify", "-format", "%wx%h", str(preview)), "360x360")
        self.assertFalse((manager.CACHE / "frames").exists())


if __name__ == "__main__":
    unittest.main()
