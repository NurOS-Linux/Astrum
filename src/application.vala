// Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
// SPDX-License-Identifier: GPL-3.0-or-later

[CCode (cheader_filename = "gtk/gtk.h")]
extern void gtk_style_context_add_provider_for_display (Gdk.Display display,
    Gtk.StyleProvider provider, uint priority);

namespace Astrum {

    public class Application : Adw.Application {

        public Application () {
            Object (
                application_id: APP_ID,
                flags: GLib.ApplicationFlags.HANDLES_OPEN
            );
        }

        construct {
            ActionEntry[] action_entries = {
                { "about", this.on_about_action },
                { "quit", this.quit },
            };
            this.add_action_entries (action_entries, this);
            const string[] quit_accels = { "<Control>q", null };
            this.set_accels_for_action ("app.quit", quit_accels);
        }

        protected override void startup () {
            base.startup ();
            load_css ();
        }

        private void load_css () {
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/org/aetherde/Astrum/style.css");
            gtk_style_context_add_provider_for_display (
                Gdk.Display.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }

        protected override void activate () {
            var window = this.active_window as Window;
            if (window == null) {
                window = new Window (this);
                window.setup_accels ();
            }
            window.present ();
        }

        protected override void open (GLib.File[] files, string hint) {
            if (files.length == 0) {
                this.activate ();
                return;
            }

            var window = this.active_window as Window;
            if (window == null) {
                window = new Window (this);
                window.setup_accels ();
            }
            window.navigate_to (files[0]);
            window.present ();
        }

        private void on_about_action () {
            var about = new Adw.AboutDialog ();
            about.application_name = APP_NAME;
            about.application_icon = APP_ID;
            about.version = APP_VERSION;
            about.copyright = "Copyright \xc2\xa9 2026 AnmiTaliDev";
            about.license_type = Gtk.License.GPL_3_0;
            about.developer_name = "AnmiTaliDev";
            about.set_property ("developers", new GLib.Variant.strv (
                { "AnmiTaliDev <anmitalidev@nuros.org>" }
            ));
            about.issue_url = "https://github.com/AetherDE/astrum/issues";
            about.present (this.active_window);
        }

        public static int main (string[] args) {
            var app = new Application ();
            return app.run (args);
        }
    }
}
