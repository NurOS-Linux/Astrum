// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum {

    public class FileManager : GLib.Object {

        public GLib.File current_directory { get; private set; }
        public GLib.ListStore file_model { get; private set; }
        public GLib.Settings settings { get; private set; }

        private GLib.FileMonitor? monitor = null;
        private GLib.Cancellable? cancellable = null;

        public signal void directory_changed (GLib.File directory);
        public signal void loading_started ();
        public signal void loading_finished ();
        public signal void error_occurred (string message);

        public FileManager () {
            file_model = new GLib.ListStore (typeof (FileItem));
            settings = new GLib.Settings (APP_ID);
        }

        public async void navigate_to (GLib.File directory) {
            if (cancellable != null) {
                cancellable.cancel ();
            }
            cancellable = new GLib.Cancellable ();

            loading_started ();
            file_model.remove_all ();

            try {
                var info = yield directory.query_info_async (
                    GLib.FileAttribute.STANDARD_TYPE,
                    GLib.FileQueryInfoFlags.NONE,
                    GLib.Priority.DEFAULT,
                    cancellable
                );

                if (info.get_file_type () != GLib.FileType.DIRECTORY) {
                    error_occurred ("Not a directory: %s".printf (directory.get_path () ?? ""));
                    loading_finished ();
                    return;
                }
            } catch (GLib.Error e) {
                if (!(e is GLib.IOError.CANCELLED)) {
                    error_occurred (e.message);
                }
                loading_finished ();
                return;
            }

            stop_monitor ();
            current_directory = directory;
            directory_changed (directory);

            yield load_directory (cancellable);
            start_monitor ();

            loading_finished ();
        }

        private async void load_directory (GLib.Cancellable? cancellable) {
            var show_hidden = settings.get_boolean ("show-hidden-files");

            try {
                var enumerator = yield current_directory.enumerate_children_async (
                    string.join (",",
                        GLib.FileAttribute.STANDARD_NAME,
                        GLib.FileAttribute.STANDARD_DISPLAY_NAME,
                        GLib.FileAttribute.STANDARD_TYPE,
                        GLib.FileAttribute.STANDARD_SIZE,
                        GLib.FileAttribute.STANDARD_CONTENT_TYPE,
                        GLib.FileAttribute.STANDARD_ICON,
                        GLib.FileAttribute.STANDARD_IS_SYMLINK,
                        GLib.FileAttribute.TIME_MODIFIED
                    ),
                    GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                    GLib.Priority.DEFAULT,
                    cancellable
                );

                var items = new GLib.List<FileItem> ();

                while (true) {
                    var infos = yield enumerator.next_files_async (
                        50, GLib.Priority.DEFAULT, cancellable
                    );

                    if (infos == null) break;

                    foreach (var info in infos) {
                        var name = info.get_name ();
                        if (!show_hidden && name.has_prefix (".")) continue;

                        var child = current_directory.get_child (name);
                        var item = new FileItem (child, info);
                        items.append (item);
                    }
                }

                sort_items (ref items);

                foreach (var item in items) {
                    file_model.append (item);
                }
            } catch (GLib.Error e) {
                if (!(e is GLib.IOError.CANCELLED)) {
                    error_occurred (e.message);
                }
            }
        }

        private void sort_items (ref GLib.List<FileItem> items) {
            var sort_by = settings.get_string ("sort-by");
            var ascending = settings.get_boolean ("sort-ascending");

            // Manual insertion sort for small lists
            var sorted = new GLib.List<FileItem> ();

            foreach (var item in items) {
                bool inserted = false;
                unowned GLib.List<FileItem>? node = sorted;
                int pos = 0;

                while (node != null) {
                    var compare = item;
                    var other = node.data;

                    // Directories first
                    int result = 0;
                    if (compare.is_directory && !other.is_directory) {
                        result = -1;
                    } else if (!compare.is_directory && other.is_directory) {
                        result = 1;
                    } else {
                        switch (sort_by) {
                            case "name":
                                result = compare.display_name.collate (other.display_name);
                                break;
                            case "size":
                                result = (int) (compare.size - other.size).clamp (-1, 1);
                                break;
                            case "modified":
                                if (compare.modified != null && other.modified != null) {
                                    result = compare.modified.compare (other.modified);
                                }
                                break;
                            case "type":
                                result = compare.content_type.collate (other.content_type);
                                if (result == 0) {
                                    result = compare.display_name.collate (other.display_name);
                                }
                                break;
                            default:
                                result = compare.display_name.collate (other.display_name);
                                break;
                        }

                        if (!ascending) result = -result;
                    }

                    if (result < 0) {
                        sorted.insert (item, pos);
                        inserted = true;
                        break;
                    }

                    node = node.next;
                    pos++;
                }

                if (!inserted) {
                    sorted.append (item);
                }
            }

            items = (owned) sorted;
        }

        private void start_monitor () {
            try {
                monitor = current_directory.monitor_directory (
                    GLib.FileMonitorFlags.WATCH_MOVES, null
                );
                monitor.changed.connect (on_directory_changed);
            } catch (GLib.Error e) {
                warning ("Failed to start file monitor: %s", e.message);
            }
        }

        private void stop_monitor () {
            if (monitor != null) {
                monitor.cancel ();
                monitor = null;
            }
        }

        private void on_directory_changed (GLib.File file, GLib.File? other,
                                            GLib.FileMonitorEvent event) {
            switch (event) {
                case GLib.FileMonitorEvent.CREATED:
                case GLib.FileMonitorEvent.DELETED:
                case GLib.FileMonitorEvent.MOVED_IN:
                case GLib.FileMonitorEvent.MOVED_OUT:
                case GLib.FileMonitorEvent.RENAMED:
                    refresh.begin ();
                    break;
                default:
                    break;
            }
        }

        public async void refresh () {
            if (current_directory != null) {
                yield navigate_to (current_directory);
            }
        }

        public bool can_go_up () {
            if (current_directory == null) return false;
            return current_directory.get_parent () != null;
        }

        public async void go_up () {
            if (!can_go_up ()) return;
            yield navigate_to (current_directory.get_parent ());
        }

        // File operations

        public async void create_folder (string name) {
            var child = current_directory.get_child (name);
            try {
                yield child.make_directory_async (GLib.Priority.DEFAULT, null);
            } catch (GLib.Error e) {
                error_occurred ("Failed to create folder: %s".printf (e.message));
            }
        }

        public async void delete_items (GLib.List<FileItem> items) {
            foreach (var item in items) {
                try {
                    if (item.is_directory) {
                        yield trash_recursively (item.file);
                    } else {
                        yield item.file.trash_async (GLib.Priority.DEFAULT, null);
                    }
                } catch (GLib.Error e) {
                    error_occurred ("Failed to delete %s: %s".printf (
                        item.display_name, e.message));
                }
            }
        }

        private async void trash_recursively (GLib.File file) throws GLib.Error {
            yield file.trash_async (GLib.Priority.DEFAULT, null);
        }

        public async void rename_item (FileItem item, string new_name) {
            try {
                yield item.file.set_display_name_async (
                    new_name, GLib.Priority.DEFAULT, null
                );
            } catch (GLib.Error e) {
                error_occurred ("Failed to rename: %s".printf (e.message));
            }
        }

        public async void copy_items (GLib.List<FileItem> items, GLib.File destination) {
            foreach (var item in items) {
                var dest_file = destination.get_child (item.name);
                try {
                    if (item.is_directory) {
                        yield copy_directory_recursive (item.file, dest_file);
                    } else {
                        yield item.file.copy_async (
                            dest_file,
                            GLib.FileCopyFlags.NONE,
                            GLib.Priority.DEFAULT,
                            null, null
                        );
                    }
                } catch (GLib.Error e) {
                    error_occurred ("Failed to copy %s: %s".printf (
                        item.display_name, e.message));
                }
            }
        }

        private async void copy_directory_recursive (GLib.File src, GLib.File dest)
                throws GLib.Error {
            yield dest.make_directory_async (GLib.Priority.DEFAULT, null);

            var enumerator = yield src.enumerate_children_async (
                string.join (",",
                    GLib.FileAttribute.STANDARD_NAME,
                    GLib.FileAttribute.STANDARD_TYPE
                ),
                GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                GLib.Priority.DEFAULT, null
            );

            while (true) {
                var infos = yield enumerator.next_files_async (
                    50, GLib.Priority.DEFAULT, null
                );
                if (infos == null) break;

                foreach (var info in infos) {
                    var child_src = src.get_child (info.get_name ());
                    var child_dest = dest.get_child (info.get_name ());

                    if (info.get_file_type () == GLib.FileType.DIRECTORY) {
                        yield copy_directory_recursive (child_src, child_dest);
                    } else {
                        yield child_src.copy_async (
                            child_dest,
                            GLib.FileCopyFlags.NONE,
                            GLib.Priority.DEFAULT,
                            null, null
                        );
                    }
                }
            }
        }

        public async void move_items (GLib.List<FileItem> items, GLib.File destination) {
            foreach (var item in items) {
                var dest_file = destination.get_child (item.name);
                try {
                    yield item.file.move_async (
                        dest_file,
                        GLib.FileCopyFlags.NONE,
                        GLib.Priority.DEFAULT,
                        null, null
                    );
                } catch (GLib.Error e) {
                    error_occurred ("Failed to move %s: %s".printf (
                        item.display_name, e.message));
                }
            }
        }
    }
}
