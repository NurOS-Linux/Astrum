// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum {

    public class Window : Adw.ApplicationWindow {

        private FileManager file_manager;
        private ClipboardManager clipboard;
        private Sidebar sidebar;
        private PathBar path_bar;
        private FileView file_view;
        private Adw.HeaderBar header_bar;
        private Gtk.Label status_label;
        private Adw.ToastOverlay toast_overlay;

        // Navigation history
        private GLib.List<GLib.File> back_stack;
        private GLib.List<GLib.File> forward_stack;
        private bool navigating_history = false;

        // Header buttons
        private Gtk.Button back_button;
        private Gtk.Button forward_button;
        private Gtk.Button up_button;

        private GLib.Settings settings;

        public Window (Astrum.Application app) {
            Object (
                application: app,
                title: APP_NAME
            );
        }

        construct {
            settings = new GLib.Settings (APP_ID);
            file_manager = new FileManager ();
            clipboard = new ClipboardManager ();
            back_stack = new GLib.List<GLib.File> ();
            forward_stack = new GLib.List<GLib.File> ();

            // Restore window state
            default_width = settings.get_int ("window-width");
            default_height = settings.get_int ("window-height");
            maximized = settings.get_boolean ("window-maximized");

            build_ui ();
            setup_actions ();
            connect_signals ();

            // Navigate to home
            var home = GLib.File.new_for_path (GLib.Environment.get_home_dir ());
            navigate_to (home);
        }

        private void build_ui () {
            // Header bar
            header_bar = new Adw.HeaderBar ();

            // Navigation buttons
            var nav_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            nav_box.add_css_class ("linked");

            back_button = new Gtk.Button.from_icon_name ("go-previous-symbolic") {
                tooltip_text = "Back",
                sensitive = false,
            };
            forward_button = new Gtk.Button.from_icon_name ("go-next-symbolic") {
                tooltip_text = "Forward",
                sensitive = false,
            };
            nav_box.append (back_button);
            nav_box.append (forward_button);
            header_bar.pack_start (nav_box);

            up_button = new Gtk.Button.from_icon_name ("go-up-symbolic") {
                tooltip_text = "Go to parent folder",
            };
            header_bar.pack_start (up_button);

            // Path bar in title
            path_bar = new PathBar ();
            header_bar.title_widget = path_bar;

            // View toggle
            var view_toggle = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            view_toggle.add_css_class ("linked");

            var list_button = new Gtk.ToggleButton () {
                icon_name = "view-list-symbolic",
                tooltip_text = "List view",
            };
            var grid_button = new Gtk.ToggleButton () {
                icon_name = "view-grid-symbolic",
                tooltip_text = "Grid view",
                group = list_button,
            };

            var mode = settings.get_string ("view-mode");
            list_button.active = mode != "grid";
            grid_button.active = mode == "grid";

            list_button.toggled.connect (() => {
                if (list_button.active) file_view.set_view_mode ("list");
            });
            grid_button.toggled.connect (() => {
                if (grid_button.active) file_view.set_view_mode ("grid");
            });

            view_toggle.append (list_button);
            view_toggle.append (grid_button);
            header_bar.pack_end (view_toggle);

            // Menu button
            var menu_button = new Gtk.MenuButton () {
                icon_name = "open-menu-symbolic",
                tooltip_text = "Menu",
                menu_model = create_app_menu (),
            };
            header_bar.pack_end (menu_button);

            // Sidebar
            sidebar = new Sidebar (settings);

            // File view
            file_view = new FileView (file_manager.file_model, settings);

            // Status bar
            status_label = new Gtk.Label ("") {
                xalign = 0,
                margin_start = 8,
                margin_end = 8,
                margin_top = 4,
                margin_bottom = 4,
            };
            status_label.add_css_class ("dim-label");
            status_label.add_css_class ("caption");

            var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                hexpand = true,
                vexpand = true,
            };
            content_box.append (file_view);
            content_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            content_box.append (status_label);

            // Split view: sidebar | content
            var sidebar_scroll = new Gtk.ScrolledWindow () {
                hscrollbar_policy = Gtk.PolicyType.NEVER,
                vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
            };
            sidebar_scroll.child = sidebar;

            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
                start_child = sidebar_scroll,
                end_child = content_box,
                shrink_start_child = false,
                shrink_end_child = false,
                position = 200,
            };

            // Toast overlay for notifications
            toast_overlay = new Adw.ToastOverlay () {
                child = paned,
            };

            // Toolbar view
            var toolbar_view = new Adw.ToolbarView ();
            toolbar_view.add_top_bar (header_bar);
            toolbar_view.content = toast_overlay;

            this.content = toolbar_view;

            // Context menu for file view
            setup_context_menu ();
        }

        private void setup_actions () {
            var action_entries = new ActionEntry[] {
                { "go-back", on_go_back },
                { "go-forward", on_go_forward },
                { "go-up", on_go_up },
                { "refresh", on_refresh },
                { "new-folder", on_new_folder },
                { "copy", on_copy },
                { "cut", on_cut },
                { "paste", on_paste },
                { "select-all", on_select_all },
                { "rename", on_rename },
                { "delete", on_delete },
                { "properties", on_properties },
                { "toggle-hidden", on_toggle_hidden },
                { "add-bookmark", on_add_bookmark },
                { "open-terminal", on_open_terminal },
            };
            this.add_action_entries (action_entries, this);
        }

        public void setup_accels () {
            var app = (Gtk.Application) this.application;
            const string[] go_back = { "<Alt>Left", null };
            const string[] go_forward = { "<Alt>Right", null };
            const string[] go_up = { "<Alt>Up", null };
            const string[] refresh = { "F5", "<Control>r", null };
            const string[] new_folder = { "<Control><Shift>n", null };
            const string[] copy = { "<Control>c", null };
            const string[] cut = { "<Control>x", null };
            const string[] paste = { "<Control>v", null };
            const string[] select_all = { "<Control>a", null };
            const string[] rename = { "F2", null };
            const string[] delete = { "Delete", null };
            const string[] properties = { "<Alt>Return", null };
            const string[] toggle_hidden = { "<Control>h", null };
            const string[] open_terminal = { "<Control><Alt>t", null };

            app.set_accels_for_action ("win.go-back", go_back);
            app.set_accels_for_action ("win.go-forward", go_forward);
            app.set_accels_for_action ("win.go-up", go_up);
            app.set_accels_for_action ("win.refresh", refresh);
            app.set_accels_for_action ("win.new-folder", new_folder);
            app.set_accels_for_action ("win.copy", copy);
            app.set_accels_for_action ("win.cut", cut);
            app.set_accels_for_action ("win.paste", paste);
            app.set_accels_for_action ("win.select-all", select_all);
            app.set_accels_for_action ("win.rename", rename);
            app.set_accels_for_action ("win.delete", delete);
            app.set_accels_for_action ("win.properties", properties);
            app.set_accels_for_action ("win.toggle-hidden", toggle_hidden);
            app.set_accels_for_action ("win.open-terminal", open_terminal);
        }

        private void connect_signals () {
            back_button.clicked.connect (on_go_back);
            forward_button.clicked.connect (on_go_forward);
            up_button.clicked.connect (on_go_up);

            sidebar.location_selected.connect ((location) => {
                navigate_to (location);
            });

            path_bar.path_selected.connect ((path) => {
                navigate_to (path);
            });

            file_view.file_activated.connect (on_file_activated);

            file_view.selection_changed.connect (() => {
                update_status ();
            });

            file_manager.directory_changed.connect ((dir) => {
                update_title (dir);
                path_bar.set_path (dir);
                update_nav_buttons ();
                update_status ();
            });

            file_manager.error_occurred.connect ((message) => {
                var toast = new Adw.Toast (message) {
                    timeout = 5,
                };
                toast_overlay.add_toast (toast);
            });

            // Save window state on close
            this.close_request.connect (() => {
                save_window_state ();
                return false;
            });
        }

        private GLib.Menu create_app_menu () {
            var menu = new GLib.Menu ();

            var view_section = new GLib.Menu ();
            view_section.append ("Show Hidden Files", "win.toggle-hidden");
            view_section.append ("Refresh", "win.refresh");
            menu.append_section (null, view_section);

            var action_section = new GLib.Menu ();
            action_section.append ("New Folder", "win.new-folder");
            action_section.append ("Add Bookmark", "win.add-bookmark");
            action_section.append ("Open Terminal", "win.open-terminal");
            menu.append_section (null, action_section);

            var app_section = new GLib.Menu ();
            app_section.append ("About Astrum", "app.about");
            menu.append_section (null, app_section);

            return menu;
        }

        private void setup_context_menu () {
            var menu = new GLib.Menu ();

            var file_section = new GLib.Menu ();
            file_section.append ("Open", "win.open-selected");
            file_section.append ("Rename", "win.rename");
            file_section.append ("Delete", "win.delete");
            file_section.append ("Properties", "win.properties");
            menu.append_section (null, file_section);

            var edit_section = new GLib.Menu ();
            edit_section.append ("Copy", "win.copy");
            edit_section.append ("Cut", "win.cut");
            edit_section.append ("Paste", "win.paste");
            menu.append_section (null, edit_section);

            var popover = new Gtk.PopoverMenu.from_model (menu) {
                has_arrow = false,
            };
            popover.set_parent (file_view);

            file_view.context_menu_requested.connect ((x, y) => {
                popover.pointing_to = { (int) x, (int) y, 1, 1 };
                popover.popup ();
            });
        }

        // Navigation

        public void navigate_to (GLib.File location) {
            if (!navigating_history && file_manager.current_directory != null) {
                back_stack.prepend (file_manager.current_directory);
                forward_stack = new GLib.List<GLib.File> ();
            }
            navigating_history = false;

            file_manager.navigate_to.begin (location);
        }

        private void on_go_back () {
            if (back_stack.length () == 0) return;
            var prev = back_stack.data;
            back_stack.remove (prev);
            forward_stack.prepend (file_manager.current_directory);
            navigating_history = true;
            file_manager.navigate_to.begin (prev);
        }

        private void on_go_forward () {
            if (forward_stack.length () == 0) return;
            var next = forward_stack.data;
            forward_stack.remove (next);
            back_stack.prepend (file_manager.current_directory);
            navigating_history = true;
            file_manager.navigate_to.begin (next);
        }

        private void on_go_up () {
            file_manager.go_up.begin ();
        }

        private void on_refresh () {
            file_manager.refresh.begin ();
        }

        // File actions

        private void on_file_activated (FileItem item) {
            if (item.is_directory) {
                navigate_to (item.file);
            } else {
                var launcher = new Gtk.FileLauncher (item.file);
                launcher.launch.begin (this, null, (obj, res) => {
                    try {
                        launcher.launch.end (res);
                    } catch (GLib.Error e) {
                        file_manager.error_occurred ("Cannot open file: %s".printf (e.message));
                    }
                });
            }
        }

        private void on_new_folder () {
            var dialog = new Adw.AlertDialog (
                "New Folder",
                "Enter the name for the new folder"
            );

            var entry = new Gtk.Entry () {
                text = "New Folder",
                activates_default = true,
            };
            dialog.extra_child = entry;

            dialog.add_response ("cancel", "Cancel");
            dialog.add_response ("create", "Create");
            dialog.default_response = "create";
            dialog.set_response_appearance ("create", Adw.ResponseAppearance.SUGGESTED);

            dialog.response.connect ((response) => {
                if (response == "create") {
                    var name = entry.text.strip ();
                    if (name.length > 0) {
                        file_manager.create_folder.begin (name);
                    }
                }
            });

            dialog.present (this);
        }

        private void on_copy () {
            var items = file_view.get_selected_items ();
            if (items.length () > 0) {
                clipboard.copy (items);
                show_toast ("Copied %u item(s)".printf (items.length ()));
            }
        }

        private void on_cut () {
            var items = file_view.get_selected_items ();
            if (items.length () > 0) {
                clipboard.cut (items);
                show_toast ("Cut %u item(s)".printf (items.length ()));
            }
        }

        private void on_paste () {
            if (clipboard.has_items) {
                clipboard.paste.begin (file_manager, file_manager.current_directory);
            }
        }

        private void on_select_all () {
            file_view.select_all ();
        }

        private void on_rename () {
            var items = file_view.get_selected_items ();
            if (items.length () != 1) return;
            var item = items.data;

            var dialog = new Adw.AlertDialog (
                "Rename",
                "Enter the new name"
            );

            var entry = new Gtk.Entry () {
                text = item.display_name,
                activates_default = true,
            };
            dialog.extra_child = entry;

            dialog.add_response ("cancel", "Cancel");
            dialog.add_response ("rename", "Rename");
            dialog.default_response = "rename";
            dialog.set_response_appearance ("rename", Adw.ResponseAppearance.SUGGESTED);

            dialog.response.connect ((response) => {
                if (response == "rename") {
                    var new_name = entry.text.strip ();
                    if (new_name.length > 0 && new_name != item.display_name) {
                        file_manager.rename_item.begin (item, new_name);
                    }
                }
            });

            dialog.present (this);
        }

        private void on_delete () {
            var items = file_view.get_selected_items ();
            if (items.length () == 0) return;

            var dialog = new Adw.AlertDialog (
                "Move to Trash?",
                "Are you sure you want to move %u item(s) to the trash?".printf (
                    items.length ())
            );

            dialog.add_response ("cancel", "Cancel");
            dialog.add_response ("delete", "Move to Trash");
            dialog.default_response = "cancel";
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    file_manager.delete_items.begin (items);
                }
            });

            dialog.present (this);
        }

        private void on_properties () {
            var items = file_view.get_selected_items ();
            if (items.length () != 1) return;

            var dialog = new PropertiesDialog (items.data);
            dialog.present (this);
        }

        private void on_toggle_hidden () {
            var current = settings.get_boolean ("show-hidden-files");
            settings.set_boolean ("show-hidden-files", !current);
            file_manager.refresh.begin ();
        }

        private void on_add_bookmark () {
            if (file_manager.current_directory != null) {
                sidebar.add_bookmark (file_manager.current_directory);
                show_toast ("Bookmark added");
            }
        }

        private void on_open_terminal () {
            var path = file_manager.current_directory?.get_path ();
            if (path == null) return;

            try {
                var app_info = GLib.AppInfo.create_from_commandline (
                    "xdg-terminal-exec",
                    null,
                    GLib.AppInfoCreateFlags.NONE
                );
                var launch_ctx = this.get_display ().get_app_launch_context ();
                launch_ctx.setenv ("PWD", path);
                app_info.launch (null, launch_ctx);
            } catch (GLib.Error e) {
                file_manager.error_occurred ("Cannot open terminal: %s".printf (e.message));
            }
        }

        // UI updates

        private void update_title (GLib.File dir) {
            var path = dir.get_path ();
            var home = GLib.Environment.get_home_dir ();
            if (path != null && path == home) {
                this.title = "Home";
            } else {
                this.title = dir.get_basename () ?? APP_NAME;
            }
        }

        private void update_nav_buttons () {
            back_button.sensitive = back_stack.length () > 0;
            forward_button.sensitive = forward_stack.length () > 0;
            up_button.sensitive = file_manager.can_go_up ();
        }

        private void update_status () {
            var total = file_manager.file_model.get_n_items ();
            var selected = file_view.get_selected_items ();
            var sel_count = selected.length ();

            if (sel_count > 0) {
                int64 total_size = 0;
                foreach (var item in selected) {
                    if (!item.is_directory) total_size += item.size;
                }
                status_label.label = "%u of %u selected (%s)".printf (
                    sel_count, total, Utils.format_size (total_size));
            } else {
                status_label.label = "%u item(s)".printf (total);
            }
        }

        private void show_toast (string message) {
            toast_overlay.add_toast (new Adw.Toast (message));
        }

        private void save_window_state () {
            settings.set_int ("window-width", default_width);
            settings.set_int ("window-height", default_height);
            settings.set_boolean ("window-maximized", maximized);
        }
    }
}
