// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum {

    public class FileView : Gtk.Box {

        private Gtk.Stack stack;
        private Gtk.ListView list_view;
        private Gtk.GridView grid_view;
        private Gtk.ScrolledWindow list_scroll;
        private Gtk.ScrolledWindow grid_scroll;
        private Gtk.MultiSelection selection_model;
        private GLib.Settings settings;

        public signal void file_activated (FileItem item);
        public signal void selection_changed ();
        public signal void context_menu_requested (double x, double y);

        public FileView (GLib.ListModel model, GLib.Settings settings) {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            this.settings = settings;

            stack = new Gtk.Stack () {
                transition_type = Gtk.StackTransitionType.CROSSFADE,
                hexpand = true,
                vexpand = true,
            };
            this.append (stack);

            selection_model = new Gtk.MultiSelection (model);
            selection_model.selection_changed.connect ((pos, n) => {
                selection_changed ();
            });

            build_list_view ();
            build_grid_view ();

            var mode = settings.get_string ("view-mode");
            stack.visible_child_name = mode == "grid" ? "grid" : "list";
        }

        private void build_list_view () {
            var factory = new Gtk.SignalListItemFactory ();
            factory.setup.connect (on_list_setup);
            factory.bind.connect (on_list_bind);

            list_view = new Gtk.ListView (selection_model, factory) {
                show_separators = true,
            };
            list_view.activate.connect (on_item_activated);

            var gesture = new Gtk.GestureClick () {
                button = Gdk.BUTTON_SECONDARY,
            };
            gesture.pressed.connect ((n, x, y) => {
                context_menu_requested (x, y);
            });
            list_view.add_controller (gesture);

            list_scroll = new Gtk.ScrolledWindow () {
                hscrollbar_policy = Gtk.PolicyType.NEVER,
                vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
                hexpand = true,
                vexpand = true,
            };
            list_scroll.child = list_view;

            stack.add_named (list_scroll, "list");
        }

        private void build_grid_view () {
            var factory = new Gtk.SignalListItemFactory ();
            factory.setup.connect (on_grid_setup);
            factory.bind.connect (on_grid_bind);

            grid_view = new Gtk.GridView (selection_model, factory) {
                max_columns = 12,
                min_columns = 3,
                single_click_activate = false,
            };
            grid_view.activate.connect (on_item_activated);

            var gesture = new Gtk.GestureClick () {
                button = Gdk.BUTTON_SECONDARY,
            };
            gesture.pressed.connect ((n, x, y) => {
                context_menu_requested (x, y);
            });
            grid_view.add_controller (gesture);

            grid_scroll = new Gtk.ScrolledWindow () {
                hscrollbar_policy = Gtk.PolicyType.NEVER,
                vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
                hexpand = true,
                vexpand = true,
            };
            grid_scroll.child = grid_view;

            stack.add_named (grid_scroll, "grid");
        }

        // List view factory

        private void on_list_setup (Gtk.SignalListItemFactory factory, GLib.Object obj) {
            var list_item = (Gtk.ListItem) obj;

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
                margin_start = 8,
                margin_end = 8,
                margin_top = 4,
                margin_bottom = 4,
            };

            var icon = new Gtk.Image () {
                pixel_size = settings.get_int ("list-icon-size"),
            };

            var name_label = new Gtk.Label (null) {
                xalign = 0,
                hexpand = true,
                ellipsize = Pango.EllipsizeMode.MIDDLE,
            };

            var size_label = new Gtk.Label (null) {
                xalign = 1,
                width_chars = 8,
            };
            size_label.add_css_class ("dim-label");
            size_label.add_css_class ("numeric");

            var date_label = new Gtk.Label (null) {
                xalign = 1,
                width_chars = 12,
            };
            date_label.add_css_class ("dim-label");

            box.append (icon);
            box.append (name_label);
            box.append (size_label);
            box.append (date_label);

            list_item.child = box;
        }

        private void on_list_bind (Gtk.SignalListItemFactory factory, GLib.Object obj) {
            var list_item = (Gtk.ListItem) obj;
            var item = (FileItem) list_item.item;
            var box = (Gtk.Box) list_item.child;

            var icon = (Gtk.Image) box.get_first_child ();
            var name_label = (Gtk.Label) icon.get_next_sibling ();
            var size_label = (Gtk.Label) name_label.get_next_sibling ();
            var date_label = (Gtk.Label) size_label.get_next_sibling ();

            if (item.icon != null) {
                icon.gicon = item.icon;
            } else {
                icon.icon_name = item.is_directory ?
                    "folder-symbolic" : "text-x-generic-symbolic";
            }

            name_label.label = item.display_name;
            size_label.label = item.get_size_string ();
            date_label.label = item.get_date_string ();
        }

        // Grid view factory

        private void on_grid_setup (Gtk.SignalListItemFactory factory, GLib.Object obj) {
            var list_item = (Gtk.ListItem) obj;

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER,
                margin_start = 4,
                margin_end = 4,
                margin_top = 4,
                margin_bottom = 4,
            };

            var icon = new Gtk.Image () {
                pixel_size = settings.get_int ("grid-icon-size"),
            };

            var label = new Gtk.Label (null) {
                xalign = 0.5f,
                justify = Gtk.Justification.CENTER,
                ellipsize = Pango.EllipsizeMode.MIDDLE,
                max_width_chars = 12,
                lines = 2,
                wrap = true,
                wrap_mode = Pango.WrapMode.WORD_CHAR,
            };

            box.append (icon);
            box.append (label);
            list_item.child = box;
        }

        private void on_grid_bind (Gtk.SignalListItemFactory factory, GLib.Object obj) {
            var list_item = (Gtk.ListItem) obj;
            var item = (FileItem) list_item.item;
            var box = (Gtk.Box) list_item.child;

            var icon = (Gtk.Image) box.get_first_child ();
            var label = (Gtk.Label) icon.get_next_sibling ();

            if (item.icon != null) {
                icon.gicon = item.icon;
            } else {
                icon.icon_name = item.is_directory ?
                    "folder" : "text-x-generic";
            }

            label.label = item.display_name;
        }

        // Actions

        private void on_item_activated (uint position) {
            var item = (FileItem) selection_model.get_item (position);
            if (item != null) {
                file_activated (item);
            }
        }

        public void set_view_mode (string mode) {
            stack.visible_child_name = mode;
            settings.set_string ("view-mode", mode);
        }

        public string get_view_mode () {
            return stack.visible_child_name;
        }

        public GLib.List<FileItem> get_selected_items () {
            var items = new GLib.List<FileItem> ();
            var bitset = selection_model.get_selection ();
            var iter = Gtk.BitsetIter ();
            uint pos;

            if (iter.init_first (bitset, out pos)) {
                do {
                    var item = (FileItem) selection_model.get_item (pos);
                    if (item != null) {
                        items.append (item);
                    }
                } while (iter.next (out pos));
            }

            return items;
        }

        public void select_all () {
            selection_model.select_all ();
        }

        public void unselect_all () {
            selection_model.unselect_all ();
        }
    }
}
