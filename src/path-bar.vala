// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum {

    public class PathBar : Gtk.Widget {

        private Gtk.Stack stack;
        private Gtk.Box crumb_box;
        private Gtk.Entry location_entry;
        private GLib.File? current_path = null;
        private bool in_edit_mode = false;

        public signal void path_selected (GLib.File path);

        static construct {
            set_layout_manager_type (typeof (Gtk.BinLayout));
            set_css_name ("pathbar");
        }

        construct {
            hexpand = true;
            overflow = Gtk.Overflow.HIDDEN;
            add_css_class ("pathbar");

            stack = new Gtk.Stack () {
                transition_type = Gtk.StackTransitionType.CROSSFADE,
                transition_duration = 120,
                hexpand = true,
                vexpand = true,
            };
            stack.set_parent (this);

            // Breadcrumb view
            var crumb_scroll = new Gtk.ScrolledWindow () {
                hscrollbar_policy = Gtk.PolicyType.EXTERNAL,
                vscrollbar_policy = Gtk.PolicyType.NEVER,
                hexpand = true,
            };
            crumb_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                valign = Gtk.Align.CENTER,
                margin_start = 6,
                margin_end = 6,
            };
            crumb_scroll.child = crumb_box;

            // Click on empty area → switch to edit mode
            var click = new Gtk.GestureClick ();
            click.pressed.connect ((n, x, y) => {
                enter_edit_mode ();
            });
            crumb_scroll.add_controller (click);

            stack.add_named (crumb_scroll, "crumbs");

            // Entry view
            location_entry = new Gtk.Entry () {
                hexpand = true,
                placeholder_text = "Enter location…",
            };
            location_entry.add_css_class ("flat");
            location_entry.add_css_class ("pathbar-entry");

            location_entry.activate.connect (on_entry_activated);

            var entry_key = new Gtk.EventControllerKey ();
            entry_key.key_pressed.connect ((keyval, keycode, state) => {
                if (keyval == Gdk.Key.Escape) {
                    leave_edit_mode ();
                    return true;
                }
                return false;
            });
            location_entry.add_controller (entry_key);

            var focus_ctrl = new Gtk.EventControllerFocus ();
            focus_ctrl.leave.connect (() => {
                // Only leave edit mode if focus moved outside the entry
                // Use idle to let GTK process the new focus target first
                GLib.Idle.add (() => {
                    if (in_edit_mode && !location_entry.has_focus) {
                        leave_edit_mode ();
                    }
                    return GLib.Source.REMOVE;
                });
            });
            location_entry.add_controller (focus_ctrl);

            stack.add_named (location_entry, "entry");
        }

        public override void dispose () {
            stack.unparent ();
            base.dispose ();
        }

        public override Gtk.SizeRequestMode get_request_mode () {
            return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
        }

        public void set_path (GLib.File path) {
            current_path = path;
            rebuild_crumbs (path);
            in_edit_mode = false;
            stack.visible_child_name = "crumbs";
        }

        private void rebuild_crumbs (GLib.File path) {
            // Remove all children
            Gtk.Widget? child = crumb_box.get_first_child ();
            while (child != null) {
                var next = child.get_next_sibling ();
                crumb_box.remove (child);
                child = next;
            }

            var home = GLib.File.new_for_path (GLib.Environment.get_home_dir ());
            var segments = build_segments (path, home);

            for (int i = 0; i < segments.length; i++) {
                var seg = segments[i];
                bool is_last = (i == segments.length - 1);
                bool is_home = (i == 0 && seg.file.equal (home));

                // Segment button
                var btn = new Gtk.Button ();
                btn.add_css_class ("flat");
                btn.add_css_class ("pathbar-crumb");
                if (is_last) btn.add_css_class ("pathbar-crumb-active");

                if (is_home) {
                    var icon = new Gtk.Image.from_icon_name ("user-home-symbolic");
                    btn.child = icon;
                    btn.tooltip_text = seg.label;
                } else {
                    var label = new Gtk.Label (seg.label) {
                        ellipsize = is_last ? Pango.EllipsizeMode.NONE : Pango.EllipsizeMode.MIDDLE,
                        max_width_chars = is_last ? -1 : 12,
                    };
                    if (is_last) label.add_css_class ("bold");
                    btn.child = label;
                }

                var target_file = seg.file;
                btn.clicked.connect (() => {
                    path_selected (target_file);
                });

                crumb_box.append (btn);

                // Separator (not after last)
                if (!is_last) {
                    var sep = new Gtk.Label ("/") {
                        valign = Gtk.Align.CENTER,
                    };
                    sep.add_css_class ("pathbar-sep");
                    crumb_box.append (sep);
                }
            }
        }

        private struct Segment {
            public GLib.File file;
            public string label;
        }

        private Segment[] build_segments (GLib.File path, GLib.File home) {
            var segments = new GLib.List<Segment?> ();
            GLib.File? current = path;

            while (current != null) {
                Segment seg = { current, display_name_for (current, home) };
                segments.prepend (seg);
                current = current.get_parent ();
            }

            var result = new Segment[segments.length ()];
            int i = 0;
            foreach (var s in segments) {
                result[i++] = s;
            }
            return result;
        }

        private string display_name_for (GLib.File file, GLib.File home) {
            if (file.equal (home)) return "Home";
            var name = file.get_basename ();
            if (name == null || name == "/") return "/";
            return name;
        }

        public void enter_edit_mode () {
            if (current_path != null) {
                location_entry.text = current_path.get_path () ?? current_path.get_uri ();
            }
            in_edit_mode = true;
            stack.visible_child_name = "entry";
            location_entry.grab_focus ();
            location_entry.select_region (0, -1);
        }

        private void leave_edit_mode () {
            if (!in_edit_mode) return;
            in_edit_mode = false;
            stack.visible_child_name = "crumbs";
        }

        private void on_entry_activated () {
            var text = location_entry.text.strip ();
            if (text.length == 0) {
                leave_edit_mode ();
                return;
            }

            GLib.File file;
            if (text.has_prefix ("/")) {
                file = GLib.File.new_for_path (text);
            } else if (text.contains ("://")) {
                file = GLib.File.new_for_uri (text);
            } else {
                file = GLib.File.new_for_path (
                    GLib.Path.build_filename (GLib.Environment.get_home_dir (), text)
                );
            }

            leave_edit_mode ();
            path_selected (file);
        }
    }
}
