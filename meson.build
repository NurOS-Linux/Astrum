# Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
# SPDX-License-Identifier: GPL-3.0-or-later

project('astrum', 'vala', 'c',
  version: '0.0.1',
  license: 'GPL-3.0-or-later',
  meson_version: '>= 0.62.0',
  default_options: [
    'warning_level=2',
    'werror=false',
  ],
)

app_id = 'org.aetherde.Astrum'
app_name = 'Astrum'

i18n = import('i18n')
gnome = import('gnome')

# Dependencies
glib_dep = dependency('glib-2.0', version: '>= 2.76')
gobject_dep = dependency('gobject-2.0')
gio_dep = dependency('gio-2.0')
gtk_dep = dependency('gtk4', version: '>= 4.12')
adw_dep = dependency('libadwaita-1', version: '>= 1.4')

conf_data = configuration_data()
conf_data.set_quoted('APP_ID', app_id)
conf_data.set_quoted('APP_NAME', app_name)
conf_data.set_quoted('APP_VERSION', meson.project_version())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))

config_file = configure_file(
  input: 'src/config.vala.in',
  output: 'config.vala',
  configuration: conf_data,
)

subdir('data')
subdir('src')
subdir('po')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
