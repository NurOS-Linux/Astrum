# Dockerfile для превью сборки Astrum File Manager
# Контейнер для быстрой проверки сборки и запуска приложения
# Не сохраняет артефакты - всё удаляется после завершения контейнера
# Поддержка WSL2 (Windows 11) с Wayland/X11
# Base: Void Linux (glibc, rolling, свежие GTK4/Vala)

FROM ghcr.io/void-linux/void-glibc-full:latest

# Установка зависимостей
# Runtime библиотеки для GTK4, Mesa (GLX/EGL/GBM), шрифты
RUN xbps-install -Suy && \
    xbps-install -y \
    base-devel \
    mold \
    vala \
    meson \
    ninja \
    gtk4-devel \
    libadwaita-devel \
    glib-devel \
    gettext \
    desktop-file-utils \
    git \
    ca-certificates \
    dbus \
    # Runtime GTK4 и LibAdwaita
    gtk4 \
    libadwaita \
    # Mesa OpenGL/GLX/EGL/GBM для аппаратного ускорения
    libglvnd \
    libdrm \
    libgbm \
    # X11 библиотеки
    libX11 \
    libXext \
    libXrender \
    libXtst \
    libXi \
    libXcursor \
    libXcomposite \
    libXdamage \
    libXfixes \
    libXrandr \
    # Шрифты для корректного отображения текста
    google-noto-fonts-ttf \
    google-noto-emoji-fonts \
    urw-fonts \
    fontconfig \
    # Утилиты для отладки
    libvulkan \
    # Для работы dbus
    dbus-libs

# Инициализация dbus
RUN rm -f /var/lib/dbus/machine-id /etc/machine-id && \
    dbus-uuidgen --ensure=/var/lib/dbus/machine-id && \
    ln -s /var/lib/dbus/machine-id /etc/machine-id

# Создаём /runtime с правами 700 (только владелец)
# Это требуется для безопасности dbus (не должно быть доступно другим)
RUN mkdir -p /runtime && chmod 700 /runtime && chown root:root /runtime

# Переменные окружения для X11/Wayland
# WSLg автоматически устанавливает WAYLAND_DISPLAY и DISPLAY
ENV XDG_RUNTIME_DIR=/runtime
ENV WAYLAND_DISPLAY=wayland-0
ENV GDK_BACKEND=wayland,x11
ENV GSK_RENDERER=cairo
ENV GTK_A11Y=none

# Рабочая директория
WORKDIR /workspace

# Копирование исходников
COPY . .

# Сборка проекта
RUN meson setup build \
    && meson compile -C build

# Компиляция GSettings схемы из исходников
RUN if [ -d data ]; then \
        glib-compile-schemas data; \
    fi

# Команда по умолчанию - запуск приложения из build директории
# Контейнер завершается вместе с приложением
# Запуск от root с AppArmor профилем для безопасности
# /runtime уже создан с правами 700, создаём dconf с правильными правами
CMD ["sh", "-c", "mkdir -p /runtime/dconf /tmp/runtime-root && \
               chmod 700 /runtime/dconf && \
               dbus-daemon --session --address=\"unix:path=/tmp/dbus-session\" --fork && \
               GSETTINGS_SCHEMA_DIR=./data \
               DBUS_SESSION_BUS_ADDRESS=\"unix:path=/tmp/dbus-session\" \
               GDK_BACKEND=wayland,x11 \
               GSK_RENDERER=cairo \
               GTK_A11Y=none \
               ./build/src/astrum"]
