# PomoPet

A calm, modern, native Pomodoro & desk-break companion for **macOS** and **Windows** with an animated pixel-art pet (**Mochi the Cat**, **Biscuit the Shiba**, or **Yuzu the Capybara**) living in your menu bar or taskbar.

## Features

- **Animated Pixel-Art Pets**: Shared 16×16 pixel-art sprite catalog (`shared/sprites.json`) with distinct animated states (`idle`, `focusing`, `stretching`, `napping`).
- **Live Session Preview**: Animated progress ring, tabular countdown, session cycle dots, and live menu bar / taskbar countdown.
- **Calm Full-Screen Break Overlay**: Translucent breathing aura, rotating desk-stretch & 20-20-20 eye-rest prompts, and non-intrusive **Snooze 5 min** / **Skip Break** controls (`Esc` to dismiss).
- **Native macOS (`macos/`)**:
  - Swift 6 + SwiftUI + AppKit (`NSStatusItem` animated pet + countdown, `NSPopover`, multi-screen translucent `NSPanel` break overlay, `UNUserNotificationCenter`, `LSUIElement = true`).
- **Native Windows (`windows/`)**:
  - C# / .NET 8 / WinUI 3 (`MicaBackdrop` main app, Win32 `Shell_NotifyIcon` animated tray pet, `ITaskbarList3` live taskbar progress bar, docked always-on-top Acrylic floating mini-pill, full-screen Acrylic break overlay, `pomopet://` URI handler).
  - **PowerToys Command Palette Companion (`PomoPet.PowerToys`)**: Connects via Named Pipe (`PomoPet.IPC.v1`) with `pomopet://` fallback to query live status and trigger Pomodoro/pet actions from PowerToys.

---

## Quick Start

### macOS (macOS 14+, Swift 6+)

```bash
cd macos

# Run core verification tests
swift run PomoPetSelfTest

# Build & package PomoPet.app (menu bar app with no Dock icon)
./scripts/bundle-macos.sh

# Launch PomoPet in your macOS menu bar
open dist/PomoPet.app
```

> Tip: Click **Preview Break** inside the popover to immediately try out the animated full-screen breathing & stretch overlay!

### Windows (Windows 10/11, .NET 8 SDK + Windows App SDK)

```powershell
# Run core & URI protocol unit tests
dotnet test windows/tests/PomoPet.Core.Tests/PomoPet.Core.Tests.csproj

# Build the WinUI 3 app and PowerToys companion
dotnet build windows/src/PomoPet.App/PomoPet.App.csproj -c Release -p:Platform=x64
dotnet build windows/src/PomoPet.PowerToys/PomoPet.PowerToys.csproj -c Release -p:Platform=x64
```

### Supported `pomopet://` URI Commands (Windows / PowerToys)
- `pomopet://start` / `pomopet://pause` / `pomopet://toggle`
- `pomopet://break` (opens break overlay preview)
- `pomopet://snooze/5`
- `pomopet://skip`
- `pomopet://pet/cat` | `pomopet://pet/dog` | `pomopet://pet/capybara`
