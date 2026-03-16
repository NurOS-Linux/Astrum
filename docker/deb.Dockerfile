# Dockerfile для сборки .deb пакетов Astrum
# Base: Debian Bookworm (совместимость с Debian 12+ и Ubuntu 22.04+)

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Установка зависимостей для сборки
RUN apt-get update && apt-get install -y --no-install-recommends \
    valac \
    meson \
    ninja-build \
    libgtk-4-dev \
    libadwaita-1-dev \
    libglib2.0-dev \
    gettext \
    desktop-file-utils \
    dpkg-dev \
    debhelper \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

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
    && DESTDIR=/workspace/install meson install -C build

# Создание структуры .deb пакета
RUN mkdir -p /workspace/deb/DEBIAN \
    && mkdir -p /workspace/deb/usr \
    && cp -r /workspace/install/* /workspace/deb/usr/ \
    && echo "Package: astrum" > /workspace/deb/DEBIAN/control \
    && echo "Version: ${VERSION}" >> /workspace/deb/DEBIAN/control \
    && echo "Section: utils" >> /workspace/deb/DEBIAN/control \
    && echo "Priority: optional" >> /workspace/deb/DEBIAN/control \
    && echo "Architecture: amd64" >> /workspace/deb/DEBIAN/control \
    && echo "Depends: libgtk-4-1, libadwaita-1-0, libglib2.0-0" >> /workspace/deb/DEBIAN/control \
    && echo "Maintainer: AnmiTaliDev <anmitalidev@nuros.org>" >> /workspace/deb/DEBIAN/control \
    && echo "Description: Modern file manager for AetherDE" >> /workspace/deb/DEBIAN/control \
    && echo " Built with GTK4 and LibAdwaita" >> /workspace/deb/DEBIAN/control \
    && echo " Homepage: https://github.com/NurOS/Astrum" >> /workspace/deb/DEBIAN/control

# Сборка .deb пакета
WORKDIR /workspace/deb
RUN dpkg-deb --build . /workspace/artifacts/astrum_${VERSION}_amd64.deb

# Директория для артефактов
VOLUME /workspace/artifacts
