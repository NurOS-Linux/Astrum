# Dockerfile для сборки .pacman пакетов Astrum
# Base: Arch Linux
# Артефакт: .pacman (совместим с pacman, формат тот же .pkg.tar.zst)

FROM archlinux:base-devel

# Обновление ключей и установка зависимостей
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syu --noconfirm --needed \
    vala \
    meson \
    ninja \
    gtk4 \
    libadwaita \
    glib2 \
    gettext \
    desktop-file-utils \
    git \
    mold \
    && pacman -Scc --noconfirm

# Настройка пользователя для makepkg (требуется не-root)
RUN useradd -m -G wheel builder

WORKDIR /workspace

# Копирование исходников
COPY . .

# Смена владельца на builder
RUN chown -R builder:builder /workspace

# Переменные окружения
# VERSION передаётся из CI/CD (из тега релиза, например v1.2.0 -> 1.2.0)
# ARCH определяется автоматически
ARG VERSION=0.0.1
ARG ARCH=x86_64
ENV VERSION=${VERSION}
ENV ARCH=${ARCH}

# Определение архитектуры
RUN if [ "$(uname -m)" = "aarch64" ]; then export ARCH=aarch64; elif [ "$(uname -m)" = "x86_64" ]; then export ARCH=x86_64; fi

# Переключение на пользователя builder
USER builder

# Сборка из исходников (без makepkg, используем meson напрямую)
RUN meson setup build && \
    meson compile -C build && \
    DESTDIR=/workspace/pkgdir meson install -C build

# Создание структуры пакета
RUN mkdir -p /workspace/pkgdir/usr && \
    cp -r /workspace/pkgdir/* /workspace/pkgdir/usr/ 2>/dev/null || true && \
    mkdir -p /workspace/artifacts

# Создание .pacman пакета (формат .pkg.tar.zst с другим именем)
RUN cd /workspace && \
    tar -czf /tmp/pkg.tar.gz -C pkgdir . && \
    zstd -19 --rm /tmp/pkg.tar.gz -o /workspace/artifacts/astrum-${VERSION}-1-${ARCH}.pkg.tar.zst

# Директория для артефактов
VOLUME /workspace/artifacts
