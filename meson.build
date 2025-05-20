project('astrum', 'cpp',
  version : '0.1.0',
  default_options : [
    'warning_level=3',
    'cpp_std=c++17',
    'buildtype=release'
  ]
)

# Компилятор и флаги
cpp = meson.get_compiler('cpp')
if cpp.get_id() == 'gcc' or cpp.get_id() == 'clang'
  add_project_arguments('-Wno-deprecated-declarations', language : 'cpp')
endif

# Qt6 зависимости
qt6 = import('qt6')
qt_deps = dependency('qt6', modules : ['Core', 'Gui', 'Widgets'])

# Опционально: проверка X11 (может потребоваться для некоторых дистрибутивов)
x11_dep = dependency('x11', required : false)
if x11_dep.found()
  qt_deps = [qt_deps, x11_dep]
endif

# MOC для обработки Q_OBJECT
moc_files = qt6.preprocess(
  moc_headers : ['astrum.hpp'],
  dependencies : qt_deps
)

# Исходные файлы
src = [
  'main.cpp',
  moc_files
]

# Создание исполняемого файла
astrum_exe = executable(
  'astrum',
  src,
  dependencies : qt_deps,
  install : true
)

# Создание директорий, если они еще не существуют
run_command('mkdir', '-p', 'data/icons', check: false)

# Установка файла рабочего стола и иконки
install_data('data/astrum.desktop', install_dir : get_option('datadir') / 'applications')
install_data('data/icons/astrum.svg', install_dir : get_option('datadir') / 'icons/hicolor/scalable/apps')

# Сообщение о завершении сборки
message('Astrum File Manager configured successfully')