// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum {

    public class PropertiesDialog : Adw.Dialog {

        public PropertiesDialog (FileItem item) {
            this.title = "Properties";
            this.content_width = 360;
            this.content_height = -1;

            build_ui (item);
        }

        private void build_ui (FileItem item) {
            var toolbar_view = new Adw.ToolbarView ();

            var header = new Adw.HeaderBar ();
            toolbar_view.add_top_bar (header);

            var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            // Icon and name
            var icon_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8) {
                halign = Gtk.Align.CENTER,
                margin_top = 24,
                margin_bottom = 16,
            };

            var icon = new Gtk.Image () {
                pixel_size = 64,
            };
            if (item.icon != null) {
                icon.gicon = item.icon;
            } else {
                icon.icon_name = item.is_directory ? "folder" : "text-x-generic";
            }

            var name_label = new Gtk.Label (item.display_name) {
                wrap = true,
                justify = Gtk.Justification.CENTER,
            };
            name_label.add_css_class ("title-2");

            icon_box.append (icon);
            icon_box.append (name_label);
            content.append (icon_box);

            // Info group
            var info_group = new Adw.PreferencesGroup () {
                margin_start = 12,
                margin_end = 12,
                margin_bottom = 12,
            };

            info_group.add (make_row ("Type", item.get_type_description ()));

            if (!item.is_directory) {
                info_group.add (make_row ("Size", item.get_size_string ()));
            }

            info_group.add (make_row ("Location", item.file.get_parent ()?.get_path () ?? ""));

            if (item.modified != null) {
                info_group.add (make_row ("Modified",
                    item.modified.format ("%Y-%m-%d %H:%M:%S")));
            }

            if (item.is_symlink) {
                info_group.add (make_row ("Symlink", "Yes"));
            }

            info_group.add (make_row ("MIME Type", item.content_type));

            content.append (info_group);

            // Permissions (async load)
            load_permissions.begin (item, content);

            toolbar_view.content = content;
            this.child = toolbar_view;
        }

        private Adw.ActionRow make_row (string title, string value) {
            var row = new Adw.ActionRow () {
                title = title,
            };

            var label = new Gtk.Label (value) {
                xalign = 1,
                selectable = true,
                ellipsize = Pango.EllipsizeMode.MIDDLE,
            };
            label.add_css_class ("dim-label");
            row.add_suffix (label);

            return row;
        }

        private async void load_permissions (FileItem item, Gtk.Box content) {
            try {
                var info = yield item.file.query_info_async (
                    string.join (",",
                        GLib.FileAttribute.OWNER_USER,
                        GLib.FileAttribute.OWNER_GROUP,
                        GLib.FileAttribute.UNIX_MODE
                    ),
                    GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                    GLib.Priority.DEFAULT,
                    null
                );

                var perm_group = new Adw.PreferencesGroup () {
                    title = "Permissions",
                    margin_start = 12,
                    margin_end = 12,
                    margin_bottom = 12,
                };

                var owner = info.get_attribute_string (GLib.FileAttribute.OWNER_USER);
                if (owner != null) {
                    perm_group.add (make_row ("Owner", owner));
                }

                var group = info.get_attribute_string (GLib.FileAttribute.OWNER_GROUP);
                if (group != null) {
                    perm_group.add (make_row ("Group", group));
                }

                if (info.has_attribute (GLib.FileAttribute.UNIX_MODE)) {
                    var mode = info.get_attribute_uint32 (GLib.FileAttribute.UNIX_MODE);
                    perm_group.add (make_row ("Permissions",
                        "%03o".printf (mode & 0777)));
                }

                content.append (perm_group);
            } catch (GLib.Error e) {
                // Permissions not available, skip
            }
        }
    }
}
