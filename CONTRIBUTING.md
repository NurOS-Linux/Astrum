# Contributing to Astrum

Thank you for your interest in contributing to Astrum!

## Ways to Contribute

- **Bug reports** — open an issue describing the problem and steps to reproduce
- **Feature requests** — open an issue with a description of the desired functionality
- **Code** — submit a pull request with bug fixes or new features
- **Translations** — contribute via [Weblate](https://hosted.weblate.org)
- **Documentation** — improve the README or other docs

## Development Setup

### Dependencies

- Vala (>= 0.56)
- Meson (>= 0.62)
- GLib (>= 2.76)
- GTK4 (>= 4.12)
- LibAdwaita (>= 1.4)

### Arch Linux

```bash
sudo pacman -S vala meson libadwaita
```

### Build

```bash
meson setup build
meson compile -C build
```

### Run (development)

```bash
GSETTINGS_SCHEMA_DIR=./data ./build/src/astrum
```

## Code Style

- File names: `kebab-case.vala`
- Classes and methods: `CamelCase` / `snake_case` per Vala conventions
- Each source file should have an SPDX license header
- Keep code organized in the `Astrum` namespace

## Translations

Translations are managed via [Weblate](https://hosted.weblate.org/projects/nuros/astrum/). To add or update a translation, contribute there rather than editing `.po` files manually.

**Translation guidelines:**
- Use a polite, formal tone
- Preserve all code placeholders and variables unchanged
- AI tools (DeepL, ChatGPT, etc.) are allowed for drafting, but raw machine translations without human review are not accepted

If you need to update the translation template locally:

```bash
ninja -C build astrum-pot
ninja -C build astrum-update-po
```

## Submitting a Pull Request

1. Fork the repository and create a branch from `main`
2. Make your changes
3. Test that the project builds and runs correctly
4. Submit a pull request with a clear description of what was changed and why

## License

By contributing, you agree that your contributions will be licensed under GPL-3.0-or-later.
