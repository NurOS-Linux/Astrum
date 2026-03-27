#!/bin/sh
# Сборка Astrum AppImage на Alpine Linux
# Использование: VERSION=1.0.0 ARCH=x86_64 ./build.sh

set -e

# Переменные окружения
VERSION=${VERSION:-0.0.1}
ARCH=${ARCH:-x86_64}

echo "=== Building Astrum AppImage ==="
echo "Version: ${VERSION}"
echo "Architecture: ${ARCH}"

# Очистка предыдущей сборки
rm -rf build/ AppDir/ artifacts/
mkdir -p artifacts

# 1. Сборка проекта (meson + ninja)
echo "=== Running meson setup ==="
meson setup build \
    --prefix=/usr \
    --buildtype=release \
    -Dbuildtype=release \
    -Db_lto=true \
    -Db_lto_mode=thin

echo "=== Running meson compile ==="
meson compile -C build

echo "=== Running meson install ==="
DESTDIR=$(pwd)/AppDir meson install -C build

# 2. Создание структуры AppDir (если meson install не создал)
echo "=== Setting up AppDir structure ==="
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/applications
mkdir -p AppDir/usr/share/icons/hicolor/scalable/apps
mkdir -p AppDir/usr/share/glib-2.0/schemas

# 3. Копирование файлов (fallback если meson install не скопировал)
if [ ! -f AppDir/usr/bin/astrum ]; then
    echo "=== Copying binary ==="
    cp build/src/astrum AppDir/usr/bin/
fi

if [ ! -f AppDir/org.aetherde.Astrum.desktop ]; then
    echo "=== Copying desktop file ==="
    if [ -f AppDir/usr/share/applications/org.aetherde.Astrum.desktop ]; then
        cp AppDir/usr/share/applications/org.aetherde.Astrum.desktop AppDir/
    elif [ -f data/org.aetherde.Astrum.desktop ]; then
        cp data/org.aetherde.Astrum.desktop AppDir/
    fi
fi

if [ ! -f AppDir/org.aetherde.Astrum.svg ]; then
    echo "=== Copying icon ==="
    if [ -f AppDir/usr/share/icons/hicolor/scalable/apps/org.aetherde.Astrum.svg ]; then
        cp AppDir/usr/share/icons/hicolor/scalable/apps/org.aetherde.Astrum.svg AppDir/
    elif [ -f data/icons/org.aetherde.Astrum.svg ]; then
        cp data/icons/org.aetherde.Astrum.svg AppDir/
    else
        # Fallback иконка
        echo '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48"><rect width="48" height="48" fill="#3388ff"/><text x="24" y="32" text-anchor="middle" fill="white" font-size="14">A</text></svg>' > AppDir/org.aetherde.Astrum.svg
    fi
fi

# 4. AppRun (кастомный — не используем linuxdeploy AppRun)
echo "=== Creating AppRun ==="
cat > AppDir/AppRun << 'EOF'
#!/bin/sh
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export GSETTINGS_SCHEMA_DIR="$HERE/usr/share/glib-2.0/schemas"
exec "$HERE/usr/bin/astrum" "$@"
EOF
chmod +x AppDir/AppRun

# 5. Компиляция GSettings схемы
if [ -d data ] && [ -f data/org.aetherde.Astrum.gschema.xml ]; then
    echo "=== Compiling GSettings schema ==="
    glib-compile-schemas data/
    cp data/gschemas.compiled AppDir/usr/share/glib-2.0/schemas/
fi

# 6. Упаковка AppImage через appimagetool
echo "=== Creating AppImage ==="
if command -v appimagetool >/dev/null 2>&1; then
    appimagetool --comp zstd AppDir artifacts/Astrum-${VERSION}-${ARCH}.AppImage
else
    echo "ERROR: appimagetool not found. Install it with: apk add appimagetool"
    exit 1
fi

# 7. Проверка результата
echo "=== Build complete ==="
ls -lh artifacts/
echo "AppImage created: artifacts/Astrum-${VERSION}-${ARCH}.AppImage"
