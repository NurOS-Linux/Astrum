# Dockerfile для сборки .AppImage пакетов Astrum
# Base: Ubuntu 20.04 (максимальная совместимость)

FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

# Обновление и установка зависимостей для сборки
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    curl \
    libfuse2 \
    && rm -rf /var/lib/apt/lists/*

# Установка appimagetool
RUN curl -L https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage \
    -o /usr/local/bin/appimagetool && \
    chmod +x /usr/local/bin/appimagetool

# Рабочая директория
WORKDIR /workspace

# Копирование исходников
COPY . .

# Переменные окружения
ARG VERSION=0.0.1
ENV VERSION=${VERSION}

# Сборка проекта
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
        # Создаём заглушку-иконку если нет файла \
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

# Создание AppImage
WORKDIR /workspace
RUN ARCH=x86_64 appimagetool AppDir /workspace/artifacts/Astrum-${VERSION}-x86_64.AppImage

# Директория для артефактов
VOLUME /workspace/artifacts
