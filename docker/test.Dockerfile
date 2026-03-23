# Dockerfile для превью сборки Astrum File Manager
# Контейнер для быстрой проверки сборки и запуска приложения
# Не сохраняет артефакты - всё удаляется после завершения контейнера
# Поддержка WSL2 (Windows 11) с Wayland/X11
# Base: Void Linux (glibc, rolling, свежие GTK4/Vala)

FROM ghcr.io/void-linux/void-glibc-full:latest

# Настройка зеркала XBPS (официальное зеркало Void Linux)
# Используем несколько зеркал для отказоустойчивости
RUN mkdir -p /etc/xbps.d && \
    echo "repository=https://repo-default.voidlinux.org/current" > /etc/xbps.d/00-repository-main.conf && \
    echo "repository=https://repo-default.voidlinux.org/current/multilib" > /etc/xbps.d/00-repository-multilib.conf

# Обновление системы и установка зависимостей с повторными попытками
# xbps-install может завершиться с ошибкой из-за сети, пробуем до 3 раз
RUN set -e; \
    for attempt in 1 2 3; do \
        echo "=== Попытка установки зависимостей #$attempt ==="; \
        if xbps-install -Suy && \
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
                dbus \
                gtk4 \
                libadwaita \
                libglvnd \
                libdrm \
                libgbm \
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
                noto-fonts-ttf \
                noto-fonts-emoji \
                fontconfig \
                dbus-libs; then \
            echo "=== Установка завершена успешно ==="; \
            break; \
        fi; \
        echo "Попытка #$attempt не удалась, ждём 10 секунд..."; \
        sleep 10; \
    done && \
    # Очистка кеша xbps для уменьшения размера образа
    xbps-remove -O && \
    rm -rf /var/cache/xbps/* && \
    rm -rf /var/db/xbps/alternatives.d/*

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
