# Docker для Astrum File Manager

## Структура

```
docker/
├── deb.Dockerfile       # Сборка .deb пакетов (Ubuntu 24.04+, Debian 13+)
├── rpm.Dockerfile       # Сборка .rpm пакетов (AlmaLinux 9, RHEL 9+, Rocky 9+)
├── pacman.Dockerfile    # Сборка .pacman пакетов (Arch Linux)
├── appimage.Dockerfile  # Сборка .AppImage (универсальный, Ubuntu 20.04 base)
├── test.Dockerfile      # Превью сборки для тестирования GUI
└── README.md            # Этот файл
```

## Использование

### Сборка пакетов

**Сборка всех пакетов одновременно:**
```bash
podman-compose build
```

**Сборка конкретного пакета:**
```bash
podman-compose build deb-builder       # .deb для Debian/Ubuntu
podman-compose build rpm-builder       # .rpm для RHEL/Fedora
podman-compose build pkg-builder       # .pacman для Arch Linux
podman-compose build appimage-builder  # .AppImage универсальный
```

**Извлечение артефактов:**
```bash
# Артефакты сохраняются в ./artifacts/
ls -la artifacts/
# astrum_0.0.1_amd64.deb
# astrum-0.0.1-1.x86_64.rpm
# astrum-0.0.1-1-x86_64.pacman
# Astrum-0.0.1-x86_64.AppImage
```

### Превью сборки (тестирование GUI)

Запуск File Manager для быстрой проверки сборки:

**Linux:**
```bash
podman-compose run --rm test
```

**Windows 11 с WSL2:**
```bash
# WSLg автоматически пробрасывает GUI - никаких дополнительных настроек не требуется
podman-compose run --rm test
```

**Что происходит:**
1. Собирается образ с зависимостями (Vala, GTK4, LibAdwaita)
2. Компилируется проект через Meson
3. Запускается бинарник `./build/src/astrum`
4. При закрытии окна контейнер удаляется вместе с артефактами

## Требования

- **Podman** — контейнеризация
- **podman-compose** — оркестрация (установка через `pip3 install podman-compose`)

### Установка зависимостей

**Fedora:**
```bash
sudo dnf install podman podman-docker
pip3 install --user podman-compose
```

**Debian/Ubuntu:**
```bash
sudo apt install podman
pip3 install --user podman-compose
```

**Arch Linux:**
```bash
sudo pacman -S podman podman-compose
```

**Windows 11:**
1. Установите WSL2: `wsl --install`
2. Установите дистрибутив Linux из Microsoft Store
3. Внутри WSL следуйте инструкциям для вашего дистрибутива выше

## Переменные окружения

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `VERSION` | Версия для сборок пакетов | `0.0.1` |
| `DISPLAY` | X11 дисплей для GUI | `:0` |
| `WAYLAND_DISPLAY` | Wayland сокет для GUI | (пусто) |
| `PULSE_SERVER` | PulseAudio сервер для звука | (пусто) |

## Примеры

**Сборка с конкретной версией:**
```bash
VERSION=1.2.3 podman-compose build deb-builder
```

**Запуск превью с очисткой кэша:**
```bash
podman-compose build --no-cache test
podman-compose run --rm test
```

**Сборка только AppImage:**
```bash
podman-compose build appimage-builder
# AppImage будет в ./artifacts/Astrum-0.0.1-x86_64.AppImage
```

## Совместимость пакетов

| Пакет | Дистрибутивы | Минимальная версия |
|-------|--------------|-------------------|
| `.deb` | Debian, Ubuntu | Ubuntu 24.04+, Debian 13+ |
| `.rpm` | RHEL, AlmaLinux, Rocky | 9+ |
| `.pacman` | Arch Linux | Любая |
| `.AppImage` | Любой Linux | Ядро 4.4+, glibc 2.17+ |
