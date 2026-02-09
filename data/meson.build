# Copyright (C) 2026 AnmiTaliDev <anmitalidev@nuros.org>
# SPDX-License-Identifier: GPL-3.0-or-later

desktop_file = i18n.merge_file(
  input: 'org.aetherde.Astrum.desktop.in',
  output: 'org.aetherde.Astrum.desktop',
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: get_option('datadir') / 'applications',
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test('Validate desktop file', desktop_utils, args: [desktop_file])
endif

# Temporary: using stock GNOME icon until designers create a new one
# install_data('icons/org.aetherde.Astrum.svg',
#   install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps',
# )

install_data('org.aetherde.Astrum.gschema.xml',
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test('Validate GSchema',
    compile_schemas,
    args: ['--strict', '--dry-run', meson.current_source_dir()],
  )
endif

astrum_resources = gnome.compile_resources('astrum-resources',
  'org.aetherde.Astrum.gresource.xml',
  c_name: 'astrum',
)
