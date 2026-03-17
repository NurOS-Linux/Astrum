# Dockerfile для превью сборки Astrum File Manager
# Контейнер для быстрой проверки сборки и запуска приложения
# Не сохраняет артефакты - всё удаляется после завершения контейнера
# Поддержка WSL2 (Windows 11) с Wayland/X11

FROM ubuntu:noble

ENV DEBIAN_FRONTEND=noninteractive

# Обновление и установка зависимостей
# Runtime библиотеки для GTK4, Mesa (GLX/EGL/GBM), шрифты
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
    dbus \
    dbus-x11 \
    # Runtime GTK4 и LibAdwaita
    libgtk-4-1 \
    libadwaita-1-0 \
    # Mesa OpenGL/GLX/EGL/GBM для аппаратного ускорения
    libgl1 \
    libglx0 \
    libglx-mesa0 \
    libgl1-mesa-dri \
    libegl1 \
    libgbm1 \
    # X11 библиотеки
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libxcursor1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    # Шрифты для корректного отображения текста
    fonts-noto-core \
    fonts-noto-color-emoji \
    fonts-urw-base35 \
    fontconfig \
    # Утилиты для отладки
    libvulkan1 \
    mesa-vulkan-drivers \
    mold \
    && rm -rf /var/lib/apt/lists/*

# Инициализация dbus
RUN dbus-uuidgen --ensure=/var/lib/dbus/machine-id

# Создаём /runtime с правами 777 чтобы user 1000 мог писать
# Это нужно для XDG_RUNTIME_DIR и dconf
RUN mkdir -p /runtime && chmod 777 /runtime

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
CMD ["sh", "-c", "mkdir -p /runtime/dconf /tmp/runtime-root && \
               chmod 700 /runtime/dconf && \
               dbus-daemon --session --address=\"unix:path=/tmp/dbus-session\" --fork && \
               GSETTINGS_SCHEMA_DIR=./data \
               DBUS_SESSION_BUS_ADDRESS=\"unix:path=/tmp/dbus-session\" \
               GDK_BACKEND=wayland,x11 \
               GSK_RENDERER=cairo \
               GTK_A11Y=none \
               ./build/src/astrum"]
