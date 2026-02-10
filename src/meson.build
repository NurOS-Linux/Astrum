# Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
# SPDX-License-Identifier: GPL-3.0-or-later

astrum_sources = files(
  'application.vala',
  'window.vala',
  'file-item.vala',
  'file-manager.vala',
  'file-view.vala',
  'sidebar.vala',
  'path-bar.vala',
  'clipboard-manager.vala',
  'properties-dialog.vala',
  'preferences-dialog.vala',
  'utils.vala',
)

astrum_deps = [
  glib_dep,
  gobject_dep,
  gio_dep,
  gtk_dep,
  adw_dep,
]

executable('astrum',
  astrum_sources,
  config_file,
  astrum_resources,
  dependencies: astrum_deps,
  vala_args: [
    '--target-glib=2.76',
  ],
  install: true,
)
