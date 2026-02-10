// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum {

    public class PathBar : Gtk.Box {

        private Gtk.Entry location_entry;

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
            // Simple path entry like Nautilus
            location_entry = new Gtk.Entry () {
                hexpand = true,
                placeholder_text = "Enter location...",
            };
            location_entry.activate.connect (on_entry_activated);
            location_entry.add_css_class ("flat");

            this.append (location_entry);
        }

        public void set_path (GLib.File path) {
            location_entry.text = path.get_path () ?? path.get_uri ();
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
        }
    }
}
