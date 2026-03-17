# AppArmor профиль для Astrum Test Container

## Установка профиля (Linux)

AppArmor профиль ограничивает возможности контейнера в целях безопасности.

### 1. Скопировать профиль в систему

```bash
sudo cp docker/astrum-test.apparmor /etc/apparmor.d/astrum-test
```

### 2. Активировать профиль

```bash
sudo apparmor_parser -r /etc/apparmor.d/astrum-test
```

Или перезагрузить службу AppArmor:

```bash
sudo systemctl restart apparmor
```

### 3. Проверить статус профиля

```bash
sudo aa-status | grep astrum-test
```

Должно показать:
```
astrum-test
```

## Что разрешено контейнеру

- ✅ Доступ к X11/Wayland socket для графики
- ✅ Доступ к `/dev/dri` для GPU acceleration
- ✅ Доступ к `/mnt/wslg` для WSLg
- ✅ Запуск `dbus-daemon` для сессии
- ✅ Чтение системных библиотек (`/usr/**`)
- ✅ Сетевой доступ для X11/Wayland

## Что запрещено контейнеру

- ❌ Доступ к `/proc/sys` и `/sys` (системные настройки)
- ❌ Доступ к `/proc/[pid]` (другие процессы)
- ❌ Монтирование файловых систем
- ❌ Загрузка модулей ядра
- ❌ Доступ к Docker socket (`/var/run/docker.sock`)
- ❌ Опасные capabilities (`sys_admin`, `sys_ptrace`, `sys_rawio`)
- ❌ Ptrace (защита от escape через отладку)

## Использование

После установки профиля контейнер автоматически будет использовать его:

```bash
docker compose run --rm test
```

## Проверка работы

Проверить что профиль активен:

```bash
sudo aa-status | grep astrum-test
```

Посмотреть логи нарушений (если есть):

```bash
sudo dmesg | grep -i apparmor
sudo journalctl -k | grep -i apparmor
```

## Временное отключение (для отладки)

```bash
# Перевести в режим жалоб (complain)
sudo aa-complain astrum-test

# Или полностью отключить
sudo aa-disable astrum-test
```

## Удаление профиля

```bash
sudo rm /etc/apparmor.d/astrum-test
sudo systemctl restart apparmor
```

## Примечания

- **Windows/WSL2**: AppArmor не работает в WSL2 по умолчанию. На Windows профиль игнорируется.
- **Только Linux**: Профиль работает только на Linux с AppArmor (Ubuntu, Debian, openSUSE).
- **Без профиля**: Контейнер будет работать, но с меньшими ограничениями безопасности.
