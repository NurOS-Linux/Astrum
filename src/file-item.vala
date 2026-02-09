// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum {

    public class FileItem : GLib.Object {

        public string name { get; set; }
        public string display_name { get; set; }
        public string path { get; set; }
        public GLib.File file { get; set; }
        public string content_type { get; set; default = "application/octet-stream"; }
        public int64 size { get; set; default = 0; }
        public GLib.DateTime? modified { get; set; default = null; }
        public bool is_directory { get; set; default = false; }
        public bool is_hidden { get; set; default = false; }
        public bool is_symlink { get; set; default = false; }
        public GLib.Icon? icon { get; set; default = null; }

        public FileItem (GLib.File file, GLib.FileInfo info) {
            this.file = file;
            this.name = info.get_name ();
            this.display_name = info.get_display_name ();
            this.path = file.get_path () ?? file.get_uri ();
            this.content_type = info.get_content_type () ?? "application/octet-stream";
            this.size = (int64) info.get_size ();
            this.is_directory = info.get_file_type () == GLib.FileType.DIRECTORY;
            this.is_hidden = name.has_prefix (".");
            this.is_symlink = info.get_is_symlink ();
            this.icon = info.get_icon ();

            var dt = info.get_modification_date_time ();
            if (dt != null) {
                this.modified = dt.to_local ();
            }
        }

        public string get_size_string () {
            if (is_directory) return "";
            return Utils.format_size (size);
        }

        public string get_date_string () {
            return Utils.format_date (modified);
        }

        public string get_type_description () {
            if (is_directory) return "Folder";
            return Utils.get_file_type_description (content_type);
        }
    }
}
