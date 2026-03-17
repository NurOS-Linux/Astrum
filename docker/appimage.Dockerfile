# Dockerfile для сборки .AppImage пакетов Astrum
# Base: appimagecrafters/ubuntu-20.04 (glibc 2.31, PPA со свежими GTK4/LibAdwaita)
# Совместимость: Любой Linux с glibc 2.31+ (Ubuntu 20.04+, Debian 11+, Fedora 33+)

FROM appimagecrafters/ubuntu-20.04:latest

ENV DEBIAN_FRONTEND=noninteractive

# Добавление PPA для свежих GTK4 и LibAdwaita
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    && add-apt-repository ppa:ubuntuhandbook1/apps \
    && apt-get update

# Установка зависимостей для сборки
RUN apt-get install -y --no-install-recommends \
    valac \
    meson \
    ninja-build \
    build-essential \
    libgtk-4-dev \
    libadwaita-1-dev \
    libglib2.0-dev \
    gettext \
    desktop-file-utils \
    git \
    ca-certificates \
    wget \
    fuse \
    && rm -rf /var/lib/apt/lists/*

# Загрузка linuxdeploy и плагина GTK4
RUN wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage \
    -O /usr/local/bin/linuxdeploy && \
    chmod +x /usr/local/bin/linuxdeploy && \
    wget -q https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/releases/download/continuous/linuxdeploy-plugin-gtk-x86_64.AppImage \
    -O /usr/local/bin/linuxdeploy-plugin-gtk && \
    chmod +x /usr/local/bin/linuxdeploy-plugin-gtk

# Рабочая директория
WORKDIR /workspace

# Копирование исходников
COPY . .

# Переменные окружения
ARG VERSION=0.0.1
ENV VERSION=${VERSION}

# Сборка проекта (флаги -march=x86-64-v3, -O2, -flto уже в meson.build)
RUN meson setup build \
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
WORKDIR /workspace
RUN VERSION=${VERSION} linuxdeploy \
    --appdir AppDir \
    --plugin gtk \
    --output appimage \
    --desktop-file=AppDir/org.aetherde.Astrum.desktop \
    --icon-file=AppDir/org.aetherde.Astrum.svg \
    --executable=AppDir/usr/bin/astrum \
    --library=AppDir/usr/lib/x86_64-linux-gnu/libgtk-4.so.1 \
    --library=AppDir/usr/lib/x86_64-linux-gnu/libadwaita-1.so.0

# Перемещение артефакта
RUN mkdir -p /workspace/artifacts && \
    mv Astrum-*.AppImage /workspace/artifacts/Astrum-${VERSION}-x86_64.AppImage || \
    mv *.AppImage /workspace/artifacts/Astrum-${VERSION}-x86_64.AppImage

# Директория для артефактов
VOLUME /workspace/artifacts
