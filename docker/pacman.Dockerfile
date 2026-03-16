# Dockerfile для сборки .pacman пакетов Astrum
# Base: Arch Linux
# Артефакт: .pacman (совместим с pacman, формат тот же .pkg.tar.zst)

FROM archlinux:base-devel

# Обновление ключей и установка зависимостей
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syu --noconfirm \
    vala \
    meson \
    ninja \
    gtk4 \
    libadwaita \
    glib2 \
    gettext \
    desktop-file-utils \
    git \
    && pacman -Scc --noconfirm

# Настройка пользователя для makepkg (требуется не-root)
RUN useradd -m -G wheel builder

WORKDIR /workspace

# Копирование исходников
COPY . .

# Смена владельца на builder
RUN chown -R builder:builder /workspace

# Переменные окружения
ARG VERSION=0.0.1
ENV VERSION=${VERSION}

# Переключение на пользователя builder
USER builder

# Создание PKGBUILD
RUN echo "# PKGBUILD for Astrum" > /workspace/PKGBUILD \
    && echo "pkgname=astrum" >> /workspace/PKGBUILD \
    && echo "pkgver=${VERSION}" >> /workspace/PKGBUILD \
    && echo "pkgrel=1" >> /workspace/PKGBUILD \
    && echo "pkgdesc='Modern file manager for AetherDE'" >> /workspace/PKGBUILD \
    && echo "arch=('x86_64')" >> /workspace/PKGBUILD \
    && echo "url='https://github.com/NurOS/Astrum'" >> /workspace/PKGBUILD \
    && echo "license=('GPL-3.0-or-later')" >> /workspace/PKGBUILD \
    && echo "depends=('gtk4' 'libadwaita' 'glib2')" >> /workspace/PKGBUILD \
    && echo "makedepends=('meson' 'ninja' 'vala' 'gettext')" >> /workspace/PKGBUILD \
    && echo "optdepends=()" >> /workspace/PKGBUILD \
    && echo "source=(\"\${pkgname}-\${pkgver}.tar.gz::https://github.com/NurOS/Astrum/archive/refs/tags/v\${pkgver}.tar.gz)" >> /workspace/PKGBUILD \
    && echo "sha256sums=('SKIP')" >> /workspace/PKGBUILD \
    && echo "" >> /workspace/PKGBUILD \
    && echo "build() {" >> /workspace/PKGBUILD \
    && echo "    cd \"\${srcdir}/\${pkgname}-\${pkgver}\"" >> /workspace/PKGBUILD \
    && echo "    arch-meson setup build" >> /workspace/PKGBUILD \
    && echo "    ninja -C build" >> /workspace/PKGBUILD \
    && echo "}" >> /workspace/PKGBUILD \
    && echo "" >> /workspace/PKGBUILD \
    && echo "package() {" >> /workspace/PKGBUILD \
    && echo "    cd \"\${srcdir}/\${pkgname}-\${pkgver}\"" >> /workspace/PKGBUILD \
    && echo "    DESTDIR=\"\${pkgdir}\" meson install -C build" >> /workspace/PKGBUILD \
    && echo "}" >> /workspace/PKGBUILD

# Альтернативный подход: прямая сборка из исходников
RUN cd /workspace && \
    meson setup build && \
    meson compile -C build && \
    DESTDIR=/workspace/pkgdir meson install -C build

# Создание пакета вручную через makepkg-подобную структуру
RUN mkdir -p /workspace/pkgdir/usr \
    && cp -r /workspace/pkgdir/* /workspace/pkgdir/usr/ 2>/dev/null || true \
    && mkdir -p /workspace/artifacts

# Создание .pacman пакета (формат .pkg.tar.zst с другим именем)
RUN cd /workspace && \
    tar -czf /tmp/pkg.tar.gz -C pkgdir . && \
    zstd -19 --rm /tmp/pkg.tar.gz -o /workspace/artifacts/astrum-${VERSION}-1-x86_64.pacman

# Директория для артефактов
VOLUME /workspace/artifacts
