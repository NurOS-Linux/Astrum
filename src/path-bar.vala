// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum {

    public class PathBar : Gtk.Box {

        private Gtk.Box breadcrumbs_box;
        private Gtk.Entry location_entry;
        private Gtk.Stack stack;
        private bool editing = false;

        public signal void path_selected (GLib.File path);

        public PathBar () {
            Object (
                orientation: Gtk.Orientation.HORIZONTAL,
                spacing: 0,
                hexpand: true
            );
            build_ui ();
        }

        private void build_ui () {
            this.add_css_class ("linked");

            stack = new Gtk.Stack () {
                hexpand = true,
                transition_type = Gtk.StackTransitionType.CROSSFADE,
            };

            // Breadcrumbs view
            var breadcrumbs_scroll = new Gtk.ScrolledWindow () {
                hscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
                vscrollbar_policy = Gtk.PolicyType.NEVER,
                hexpand = true,
            };

            breadcrumbs_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            breadcrumbs_box.add_css_class ("linked");
            breadcrumbs_scroll.child = breadcrumbs_box;

            stack.add_named (breadcrumbs_scroll, "breadcrumbs");

            // Text entry view
            location_entry = new Gtk.Entry () {
                hexpand = true,
                placeholder_text = "Enter location...",
            };
            location_entry.activate.connect (on_entry_activated);

            var entry_key = new Gtk.EventControllerKey ();
            entry_key.key_pressed.connect ((keyval, keycode, state) => {
                if (keyval == Gdk.Key.Escape) {
                    switch_to_breadcrumbs ();
                    return true;
                }
                return false;
            });
            location_entry.add_controller (entry_key);

            stack.add_named (location_entry, "entry");
            stack.visible_child_name = "breadcrumbs";

            this.append (stack);

            // Edit button
            var edit_button = new Gtk.Button.from_icon_name ("document-edit-symbolic") {
                tooltip_text = "Edit path",
                valign = Gtk.Align.CENTER,
            };
            edit_button.add_css_class ("flat");
            edit_button.clicked.connect (toggle_edit_mode);
            this.append (edit_button);
        }

        public void set_path (GLib.File path) {
            // Clear existing breadcrumbs
            var child = breadcrumbs_box.get_first_child ();
            while (child != null) {
                var next = child.get_next_sibling ();
                breadcrumbs_box.remove (child);
                child = next;
            }

            // Build crumbs from path
            var parts = new GLib.List<GLib.File> ();
            var current = path;
            while (current != null) {
                parts.prepend (current);
                current = current.get_parent ();
            }

            bool first = true;
            foreach (var part in parts) {
                if (!first) {
                    var sep = new Gtk.Label ("/");
                    sep.add_css_class ("dim-label");
                    breadcrumbs_box.append (sep);
                }

                var name = part.get_basename ();
                if (name == "/") name = "/";
                else if (part.get_path () == GLib.Environment.get_home_dir ()) name = "Home";

                var button = new Gtk.Button.with_label (name);
                button.add_css_class ("flat");
                var target = part;
                button.clicked.connect (() => {
                    path_selected (target);
                });

                breadcrumbs_box.append (button);
                first = false;
            }

            location_entry.text = path.get_path () ?? path.get_uri ();

            if (editing) {
                switch_to_breadcrumbs ();
            }
        }

        private void toggle_edit_mode () {
            if (editing) {
                switch_to_breadcrumbs ();
            } else {
                switch_to_entry ();
            }
        }

        private void switch_to_entry () {
            editing = true;
            stack.visible_child_name = "entry";
            location_entry.grab_focus ();
            location_entry.select_region (0, -1);
        }

        private void switch_to_breadcrumbs () {
            editing = false;
            stack.visible_child_name = "breadcrumbs";
        }

        private void on_entry_activated () {
            var text = location_entry.text.strip ();
            if (text.length == 0) return;

            GLib.File file;
            if (text.has_prefix ("/")) {
                file = GLib.File.new_for_path (text);
            } else if (text.contains ("://")) {
                file = GLib.File.new_for_uri (text);
            } else {
                // Treat as relative to home
                file = GLib.File.new_for_path (
                    GLib.Path.build_filename (GLib.Environment.get_home_dir (), text)
                );
            }

            path_selected (file);
            switch_to_breadcrumbs ();
        }
    }
}
