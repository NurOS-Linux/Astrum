// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

namespace Astrum.Utils {

    public string format_size (int64 size) {
        if (size < 0) return "";
        return GLib.format_size ((uint64) size);
    }

    public string format_date (GLib.DateTime? dt) {
        if (dt == null) return "";

        var now = new GLib.DateTime.now_local ();
        var diff = now.difference (dt);

        if (diff < GLib.TimeSpan.DAY) {
            return dt.format ("%H:%M");
        } else if (diff < 7 * GLib.TimeSpan.DAY) {
            return dt.format ("%a %H:%M");
        } else if (dt.get_year () == now.get_year ()) {
            return dt.format ("%e %b");
        } else {
            return dt.format ("%e %b %Y");
        }
    }

    public string get_mime_icon_name (string content_type) {
        var icon = GLib.ContentType.get_icon (content_type);
        if (icon is GLib.ThemedIcon) {
            var themed = (GLib.ThemedIcon) icon;
            if (themed.get_names ().length > 0) return themed.get_names ()[0];
        }
        return "text-x-generic";
    }

    public string get_file_type_description (string content_type) {
        return GLib.ContentType.get_description (content_type);
    }

    public bool is_text_file (string content_type) {
        return GLib.ContentType.is_a (content_type, "text/plain");
    }
}
