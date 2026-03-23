# Dockerfile для сборки .AppImage пакетов Astrum
# Base: Alpine 3.21 (cutting edge, GTK4 из репозитория Alpine)
# Статическая линковка: libc, libgcc, libstdc++
# Совместимость: Любой Linux с glibc 2.31+

FROM alpine:3.21

ENV APK_REPOSITORIES="https://dl-cdn.alpinelinux.org/alpine/v3.21/main\nhttps://dl-cdn.alpinelinux.org/alpine/v3.21/community"

# Установка зависимостей для сборки
RUN apk add --no-cache \
    vala \
    meson \
    ninja \
    build-base \
    glib-dev \
    gtk4.0-dev \
    libadwaita-dev \
    gettext \
    desktop-file-utils \
    git \
    curl \
    ca-certificates \
    wget \
    fuse \
    fuse-dev \
    patchelf \
    mold \
    # Статические библиотеки для линковки
    musl-dev \
    libgcc \
    libstdc++ \
    glib-static \
    && rm -rf /var/cache/apk/*

# Загрузка appimagetool (нет в репозитории Alpine 3.21)
RUN curl -sSL https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage \
    -o /usr/local/bin/appimagetool && \
    chmod +x /usr/local/bin/appimagetool

# Загрузка linuxdeploy и плагина GTK4
RUN curl -sSL https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage \
    -o /usr/local/bin/linuxdeploy && \
    chmod +x /usr/local/bin/linuxdeploy && \
    curl -sSL https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/releases/download/continuous/linuxdeploy-plugin-gtk-x86_64.AppImage \
    -o /usr/local/bin/linuxdeploy-plugin-gtk && \
    chmod +x /usr/local/bin/linuxdeploy-plugin-gtk

# Рабочая директория
WORKDIR /workspace

# Копирование исходников
COPY . .

# Переменные окружения
ARG VERSION=0.0.1
ENV VERSION=${VERSION}

# Флаги для статической линковки
# -static: статическая линковка libc (musl)
# -static-libgcc: статическая линковка libgcc
# -Wl,-Bstatic: линковать следующие библиотеки статически
# -fuse-ld=mold: быстрый линкер mold (требуется для LTO в meson.build)
ENV CFLAGS="-O2 -march=x86-64-v3 -flto=auto -ffat-lto-objects"
ENV CXXFLAGS="-O2 -march=x86-64-v3 -flto=auto -ffat-lto-objects -static-libgcc"
ENV LDFLAGS="-fuse-ld=mold -static -static-libgcc -Wl,-Bstatic -lglib-2.0 -Wl,-Bdynamic"

# Сборка проекта
RUN meson setup build \
    -Dbuildtype=release \
    -Db_lto=true \
    -Db_lto_mode=thin \
    && meson compile -C build \
    && DESTDIR=/workspace/AppDir/usr meson install -C build

# Создание структуры AppDir
RUN mkdir -p /workspace/AppDir/usr/share/applications \
    && mkdir -p /workspace/AppDir/usr/share/icons/hicolor/scalable/apps \
    && mkdir -p /workspace/AppDir/usr/share/glib-2.0/schemas

# Копирование desktop файла
RUN if [ -f data/org.aetherde.Astrum.desktop ]; then \
        cp data/org.aetherde.Astrum.desktop /workspace/AppDir/usr/share/applications/; \
    fi

# Копирование иконки (если есть)
RUN if [ -f data/icons/org.aetherde.Astrum.svg ]; then \
        cp data/icons/org.aetherde.Astrum.svg /workspace/AppDir/usr/share/icons/hicolor/scalable/apps/; \
    else \
        echo '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48"><rect width="48" height="48" fill="#3388ff"/><text x="24" y="32" text-anchor="middle" fill="white" font-size="14">A</text></svg>' \
        > /workspace/AppDir/usr/share/icons/hicolor/scalable/apps/org.aetherde.Astrum.svg; \
    fi

# Компиляция GSettings схемы
RUN if [ -d data ]; then \
        glib-compile-schemas data && \
        cp data/gschemas.compiled /workspace/AppDir/usr/share/glib-2.0/schemas/; \
    fi

# Создание AppRun
RUN echo '#!/bin/bash' > /workspace/AppDir/AppRun && \
    echo 'HERE="$(dirname "$(readlink -f "${0}")")"' >> /workspace/AppDir/AppRun && \
    echo 'export GSETTINGS_SCHEMA_DIR="${HERE}/usr/share/glib-2.0/schemas"' >> /workspace/AppDir/AppRun && \
    echo 'exec "${HERE}/usr/bin/astrum" "$@"' >> /workspace/AppDir/AppRun && \
    chmod +x /workspace/AppDir/AppRun

# Создание desktop файла в корне AppDir
RUN cp /workspace/AppDir/usr/share/applications/org.aetherde.Astrum.desktop /workspace/AppDir/org.aetherde.Astrum.desktop

# Копирование иконки в корень AppDir
RUN cp /workspace/AppDir/usr/share/icons/hicolor/scalable/apps/org.aetherde.Astrum.svg /workspace/AppDir/org.aetherde.Astrum.svg

# Создание AppImage через linuxdeploy с плагином GTK4
# --exclude-library: исключение библиотек, которые будут прилинкованы статически
WORKDIR /workspace
RUN VERSION=${VERSION} linuxdeploy \
    --appdir AppDir \
    --plugin gtk \
    --output appimage \
    --desktop-file=AppDir/org.aetherde.Astrum.desktop \
    --icon-file=AppDir/org.aetherde.Astrum.svg \
    --executable=AppDir/usr/bin/astrum \
    --exclude-library=libc.so.6 \
    --exclude-library=libm.so.6 \
    --exclude-library=libpthread.so.0 \
    --exclude-library=libgcc_s.so.1 \
    --exclude-library=libstdc++.so.6 \
    --exclude-library=libglib-2.0.so.0 \
    --exclude-library=libgobject-2.0.so.0 \
    --exclude-library=libgio-2.0.so.0

# Перемещение артефакта
RUN mkdir -p /workspace/artifacts && \
    mv Astrum-*.AppImage /workspace/artifacts/Astrum-${VERSION}-x86_64.AppImage || \
    mv *.AppImage /workspace/artifacts/Astrum-${VERSION}-x86_64.AppImage

# Директория для артефактов
VOLUME /workspace/artifacts
