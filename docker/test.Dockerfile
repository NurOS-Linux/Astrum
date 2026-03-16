# Dockerfile для превью сборки Astrum File Manager
# Контейнер для быстрой проверки сборки и запуска приложения
# Не сохраняет артефакты - всё удаляется после завершения контейнера

FROM ubuntu:noble

ENV DEBIAN_FRONTEND=noninteractive

# Обновление и установка зависимостей
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
    libegl1 \
    libgl1 \
    libglx0 \
    libgbm1 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    && rm -rf /var/lib/apt/lists/*

# Инициализация dbus и создание runtime директории
RUN dbus-uuidgen --ensure=/var/lib/dbus/machine-id && \
    mkdir -p /tmp/runtime-root && \
    chmod 700 /tmp/runtime-root

# Переменные окружения для X11/Wayland
# WSLg автоматически устанавливает DISPLAY
ENV XDG_RUNTIME_DIR=/tmp/runtime-root

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
# GTK_A11Y=none отключает accessibility (не нужен в контейнере)
# GDK_BACKEND=x11 принудительно использует X11 вместо Wayland для совместимости
CMD ["sh", "-c", "mkdir -p /tmp/runtime-root && \
               dbus-daemon --session --address=\"unix:path=/tmp/dbus-session\" --fork && \
               GSETTINGS_SCHEMA_DIR=./data \
               DBUS_SESSION_BUS_ADDRESS=\"unix:path=/tmp/dbus-session\" \
               GTK_A11Y=none \
               GDK_BACKEND=x11 \
               ./build/src/astrum"]
