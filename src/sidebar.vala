// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum {

    public class Sidebar : Gtk.Box {

        private Gtk.ListBox places_list;
        private Gtk.ListBox bookmarks_list;
        private GLib.Settings settings;

        public signal void location_selected (GLib.File location);

        public Sidebar (GLib.Settings settings) {
            Object (
                orientation: Gtk.Orientation.VERTICAL,
                spacing: 0
            );
            this.settings = settings;
            build_ui ();
        }

        private void build_ui () {
            this.add_css_class ("navigation-sidebar");
            this.width_request = 200;

            // Places section
            var places_label = new Gtk.Label ("Places") {
                xalign = 0,
                margin_start = 12,
                margin_top = 12,
                margin_bottom = 6,
            };
            places_label.add_css_class ("heading");
            this.append (places_label);

            places_list = new Gtk.ListBox () {
                selection_mode = Gtk.SelectionMode.SINGLE,
            };
            places_list.add_css_class ("navigation-sidebar");
            places_list.row_activated.connect (on_place_activated);
            this.append (places_list);

            // Add standard XDG locations
            add_place ("Home", "user-home-symbolic",
                GLib.Environment.get_home_dir ());
            add_place ("Desktop", "user-desktop-symbolic",
                GLib.Environment.get_user_special_dir (GLib.UserDirectory.DESKTOP));
            add_place ("Documents", "folder-documents-symbolic",
                GLib.Environment.get_user_special_dir (GLib.UserDirectory.DOCUMENTS));
            add_place ("Downloads", "folder-download-symbolic",
                GLib.Environment.get_user_special_dir (GLib.UserDirectory.DOWNLOAD));
            add_place ("Music", "folder-music-symbolic",
                GLib.Environment.get_user_special_dir (GLib.UserDirectory.MUSIC));
            add_place ("Pictures", "folder-pictures-symbolic",
                GLib.Environment.get_user_special_dir (GLib.UserDirectory.PICTURES));
            add_place ("Videos", "folder-videos-symbolic",
                GLib.Environment.get_user_special_dir (GLib.UserDirectory.VIDEOS));

            var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
                margin_top = 6,
                margin_bottom = 6,
            };
            this.append (sep);

            // System locations
            add_place ("Trash", "user-trash-symbolic", "trash:///");
            add_place ("File System", "drive-harddisk-symbolic", "/");

            // Bookmarks section
            var bookmarks_label = new Gtk.Label ("Bookmarks") {
                xalign = 0,
                margin_start = 12,
                margin_top = 12,
                margin_bottom = 6,
            };
            bookmarks_label.add_css_class ("heading");
            this.append (bookmarks_label);

            bookmarks_list = new Gtk.ListBox () {
                selection_mode = Gtk.SelectionMode.SINGLE,
            };
            bookmarks_list.add_css_class ("navigation-sidebar");
            bookmarks_list.row_activated.connect (on_bookmark_activated);
            this.append (bookmarks_list);

            load_bookmarks ();
        }

        private void add_place (string label, string icon_name, string? path) {
            if (path == null) return;

            var row = new Gtk.ListBoxRow ();
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
                margin_start = 8,
                margin_end = 8,
                margin_top = 4,
                margin_bottom = 4,
            };

            var icon = new Gtk.Image.from_icon_name (icon_name);
            var name_label = new Gtk.Label (label) {
                xalign = 0,
                hexpand = true,
                ellipsize = Pango.EllipsizeMode.END,
            };

            box.append (icon);
            box.append (name_label);
            row.child = box;
            row.set_data ("path", path);

            places_list.append (row);
        }

        private void on_place_activated (Gtk.ListBoxRow row) {
            var path = row.get_data<string> ("path");
            if (path != null) {
                GLib.File file;
                if (path.has_prefix ("/") || path.contains ("://")) {
                    file = GLib.File.new_for_uri (
                        path.has_prefix ("/") ? "file://" + path : path
                    );
                } else {
                    file = GLib.File.new_for_path (path);
                }
                location_selected (file);
            }
        }

        private void on_bookmark_activated (Gtk.ListBoxRow row) {
            var path = row.get_data<string> ("path");
            if (path != null) {
                location_selected (GLib.File.new_for_uri (path));
            }
        }

        private void load_bookmarks () {
            var bookmarks = settings.get_strv ("bookmarks");
            foreach (var uri in bookmarks) {
                add_bookmark_row (uri);
            }
        }

        private void add_bookmark_row (string uri) {
            var file = GLib.File.new_for_uri (uri);
            var basename = file.get_basename () ?? uri;

            var row = new Gtk.ListBoxRow ();
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
                margin_start = 8,
                margin_end = 8,
                margin_top = 4,
                margin_bottom = 4,
            };

            var icon = new Gtk.Image.from_icon_name ("folder-symbolic");
            var label = new Gtk.Label (basename) {
                xalign = 0,
                hexpand = true,
                ellipsize = Pango.EllipsizeMode.END,
            };

            box.append (icon);
            box.append (label);
            row.child = box;
            row.set_data ("path", uri);

            bookmarks_list.append (row);
        }

        public void add_bookmark (GLib.File location) {
            var uri = location.get_uri ();
            string[] bookmarks = settings.get_strv ("bookmarks");

            // Don't add duplicates
            foreach (string b in bookmarks) {
                if (b == uri) return;
            }

            var builder = new GLib.VariantBuilder (GLib.VariantType.STRING_ARRAY);
            foreach (string b in bookmarks) {
                builder.add ("s", b);
            }
            builder.add ("s", uri);

            settings.set_value ("bookmarks", builder.end ());

            add_bookmark_row (uri);
        }
    }
}
