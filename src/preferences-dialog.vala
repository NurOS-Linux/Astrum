// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum {

    public class PreferencesDialog : Adw.PreferencesDialog {

        private GLib.Settings settings;

        public PreferencesDialog (GLib.Settings settings) {
            this.settings = settings;
            build_ui ();
        }

        private void build_ui () {
            var page = new Adw.PreferencesPage () {
                title = "Preferences",
                icon_name = "preferences-system-symbolic",
            };

            // View settings group
            var view_group = new Adw.PreferencesGroup () {
                title = "View",
                description = "Customize how files are displayed",
            };

            // List icon size
            var list_adjustment = new Gtk.Adjustment (
                settings.get_int ("list-icon-size"),
                16, 64, 1, 8, 0
            );
            var list_size_row = new Adw.SpinRow (list_adjustment, 1, 0);
            list_size_row.title = "List View Icon Size";
            list_size_row.subtitle = "Size of icons in list view (16-64 pixels)";
            list_size_row.adjustment.value_changed.connect (() => {
                settings.set_int ("list-icon-size", (int) list_size_row.value);
            });
            view_group.add (list_size_row);

            // Grid icon size
            var grid_adjustment = new Gtk.Adjustment (
                settings.get_int ("grid-icon-size"),
                32, 128, 1, 8, 0
            );
            var grid_size_row = new Adw.SpinRow (grid_adjustment, 1, 0);
            grid_size_row.title = "Grid View Icon Size";
            grid_size_row.subtitle = "Size of icons in grid view (32-128 pixels)";
            grid_size_row.adjustment.value_changed.connect (() => {
                settings.set_int ("grid-icon-size", (int) grid_size_row.value);
            });
            view_group.add (grid_size_row);

            page.add (view_group);
            this.add (page);
        }
    }
}
