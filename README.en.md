# Feibi Codex Pet

[中文说明](README.md)

Feibi is a chibi animated pet for Codex Desktop. She uses a soft, low-contrast palette inspired by the original character, types on a laptop while Codex is working, and shows a cheerful “菲比 / 啾比” comic bubble on hover.

![Feibi state overview](assets/preview-contact-sheet.png)

| Active task | Happy bubble |
| --- | --- |
| ![Feibi coding on a laptop](assets/running-laptop.gif) | ![Feibi happy comic bubble](assets/happy-bubble.gif) |

## Features

- Soft pastel, original-like chibi styling
- Laptop coding animation during an active task
- Happy hover animation with a “菲比 / 啾比” speech bubble
- 16 pointer-facing look directions
- Transparent Codex v2 pet atlas

## Requirements

- A Codex Desktop version that supports custom pets
- Windows PowerShell 5.1 or later

## Quick install

Clone this repository, open PowerShell in its root, and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

The installer copies only Feibi's two runtime files to `%USERPROFILE%\.codex\pets\maomao`. If that pet already exists, it is preserved as a timestamped backup first.

Restart Codex Desktop after installation. If the pet list does not refresh immediately, restart the app or reopen the pet selector.

## Manual install

1. Create `%USERPROFILE%\.codex\pets\maomao`.
2. Copy `pet/maomao/pet.json` and `pet/maomao/spritesheet.webp` into it.
3. Restart Codex Desktop and select “菲比” in the pet selector.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
```

The uninstaller only handles `%USERPROFILE%\.codex\pets\maomao`; it does not modify other pets.

## Click behavior and limitation

Clicking Feibi keeps Codex Desktop's native behavior: it opens and focuses the main Codex window. The current custom-pet schema cannot bind a click-only animation, so the “菲比 / 啾比” comic bubble is presented on hover.

## Package layout

```text
assets/          GitHub preview images and GIFs
pet/maomao/      Installable pet.json and spritesheet.webp
scripts/         Install and uninstall scripts
tests/           Package and asset validation
```

Validate the package with:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Test-Package.ps1
```

`checksums.sha256` records SHA-256 values for the installable manifest and atlas so release artifacts can be verified.

See [CONTRIBUTING.md](CONTRIBUTING.md) before contributing. Report security issues according to [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
