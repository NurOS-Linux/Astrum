# Dockerfile для сборки .AppImage пакетов Astrum
# Base: Alpine 3.21 (stable, GTK4 из репозитория Alpine)
# Гибридная линковка:
#   - Статически: musl libc, libgcc (для независимости от glibc)
#   - Динамически: GTK4, libadwaita, glib (AppImage упакует .so внутри)
# Совместимость: Любой Linux (musl внутри AppImage)

FROM alpine:3.21

# Alpine 3.21 stable репозитории
# appimagetool отсутствует в репозиториях Alpine — загружаем бинарник вручную
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

# Загрузка appimagetool (отсутствует в репозиториях Alpine)
RUN wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage \
    -O /usr/local/bin/appimagetool && \
    chmod +x /usr/local/bin/appimagetool

# Загрузка linuxdeploy и плагина GTK4 (отсутствуют в репозиториях Alpine)
RUN curl -sSL https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage \
    -o /usr/local/bin/linuxdeploy && \
    chmod +x /usr/local/bin/linuxdeploy && \
    curl -sSL https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/releases/download/continuous/linuxdeploy-plugin-gtk-x86_64.AppImage \
    -o /usr/local/bin/linuxdeploy-plugin-gtk && \
    chmod +x /usr/local/bin/linuxdeploy-plugin-gtk

# Рабочая директория
WORKDIR /workspace

# Копирование cross-file для meson
COPY docker/alpine-cross.txt /workspace/alpine-cross.txt

# Копирование скрипта сборки
COPY docker/build.sh /workspace/build.sh
RUN chmod +x /workspace/build.sh

# Копирование исходников
COPY . .

# Переменные окружения
ARG VERSION=0.0.1
ARG ARCH=x86_64
ENV VERSION=${VERSION}
ENV ARCH=${ARCH}

# Определение архитектуры
RUN if [ "$(uname -m)" = "aarch64" ]; then export ARCH=aarch64; elif [ "$(uname -m)" = "x86_64" ]; then export ARCH=x86_64; fi

# Запуск скрипта сборки AppImage
# build.sh выполняет: meson setup/compile/install, создание AppDir, упаковку appimagetool
RUN /workspace/build.sh

# Директория для артефактов
VOLUME /workspace/artifacts
