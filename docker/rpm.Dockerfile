# Dockerfile для сборки .rpm пакетов Astrum
# Base: Fedora 41 (glib 2.82+, GTK4 4.16+)
# Совместимость: Fedora 41+, RHEL 9+ (с пересборкой)

FROM fedora:41

ENV DEBIAN_FRONTEND=noninteractive

# Установка зависимостей для сборки
RUN dnf install -y \
    vala \
    meson \
    ninja-build \
    gtk4-devel \
    libadwaita-devel \
    glib2-devel \
    gettext \
    desktop-file-utils \
    rpm-build \
    rpmdevtools \
    git \
    mold \
    && dnf clean all

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

# Создание структуры RPM пакета
RUN mkdir -p /workspace/rpmbuild/BUILD \
    && mkdir -p /workspace/rpmbuild/RPMS \
    && mkdir -p /workspace/rpmbuild/SOURCES \
    && mkdir -p /workspace/rpmbuild/SPECS \
    && mkdir -p /workspace/rpmbuild/SRPM \
    && mkdir -p /workspace/rpmbuild/BUILDROOT

# Копирование установленных файлов в BUILDROOT
RUN mkdir -p /workspace/rpmbuild/BUILDROOT/astrum-${VERSION}-1.x86_64/usr \
    && cp -r /workspace/install/* /workspace/rpmbuild/BUILDROOT/astrum-${VERSION}-1.x86_64/usr/

# Создание spec файла
RUN echo "Name:           astrum" > /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "Version:        ${VERSION}" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "Release:        1%{?dist}" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "Summary:        Modern file manager for AetherDE" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "License:        GPL-3.0-or-later" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "URL:            https://github.com/NurOS/Astrum" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "BuildArch:      x86_64" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "Requires:       gtk4" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "Requires:       libadwaita" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "Requires:       glib2" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "%description" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "Modern file manager for AetherDE, built with Vala, GTK4, and LibAdwaita." >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "%install" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "mkdir -p %{buildroot}/usr" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "cp -r /workspace/install/* %{buildroot}/usr/" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "%files" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "/usr/bin/astrum" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "/usr/share/applications/org.aetherde.Astrum.desktop" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "/usr/share/glib-2.0/schemas/org.aetherde.Astrum.gschema.xml" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "/usr/share/icons/hicolor/scalable/apps/org.aetherde.Astrum.svg" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "%post" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "update-desktop-database &>/dev/null || :" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null || :" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "%postun" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "update-desktop-database &>/dev/null || :" >> /workspace/rpmbuild/SPECS/astrum.spec \
    && echo "glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null || :" >> /workspace/rpmbuild/SPECS/astrum.spec

# Сборка .rpm пакета
WORKDIR /workspace/rpmbuild
RUN mkdir -p /workspace/artifacts && \
    rpmbuild -bb SPECS/astrum.spec --define "_topdir /workspace/rpmbuild" && \
    cp RPMS/x86_64/astrum-${VERSION}-1.x86_64.rpm /workspace/artifacts/astrum-${VERSION}-1.x86_64.rpm

# Директория для артефактов
VOLUME /workspace/artifacts
