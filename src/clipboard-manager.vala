// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum {

    public enum ClipboardAction {
        COPY,
        CUT;
    }

    public class ClipboardManager : GLib.Object {

        private ClipboardAction _action = ClipboardAction.COPY;
        private GLib.List<FileItem>? _items = null;

        public bool has_items {
            get { return _items != null && _items.length () > 0; }
        }

        public signal void changed ();

        public void copy (GLib.List<FileItem> selection) {
            _items = new GLib.List<FileItem> ();
            foreach (var item in selection) {
                _items.append (item);
            }
            _action = ClipboardAction.COPY;
            changed ();
        }

        public void cut (GLib.List<FileItem> selection) {
            _items = new GLib.List<FileItem> ();
            foreach (var item in selection) {
                _items.append (item);
            }
            _action = ClipboardAction.CUT;
            changed ();
        }

        public async void paste (FileManager file_manager, GLib.File destination) {
            if (!has_items || _items == null) return;

            if (_action == ClipboardAction.COPY) {
                yield file_manager.copy_items (_items, destination);
            } else {
                yield file_manager.move_items (_items, destination);
                clear ();
            }
        }

        public void clear () {
            _items = null;
            changed ();
        }
    }
}
