# AGENTS.md — PomoPet

## Overview

**PomoPet** is a dual-native Pomodoro & desk-break companion for **macOS** and **Windows** featuring an animated 16×16 pixel-art pet (**Mochi the Cat**, **Biscuit the Shiba**, or **Yuzu the Capybara**) living in the macOS menu bar or Windows taskbar/tray. Both platforms share a single pixel-art sprite catalog (`shared/sprites.json`) and implement parallel Pomodoro engines, live countdown indicators, and calm full-screen breathing/stretch break overlays.

## Tech Stack & Requirements

- **macOS (`macos/`)**: Swift `6.0` (SwiftPM), SwiftUI + AppKit (`NSStatusItem`, `NSPopover`, multi-screen `NSPanel`, `UNUserNotificationCenter`), macOS `14.0+` (`LSUIElement = true`, no Dock icon)
- **Windows (`windows/`)**: C# / `.NET 11` (`net11.0` for `PomoPet.Core`, `net11.0-windows10.0.19041.0` for `PomoPet.App` & `PomoPet.PowerToys`), WinUI 3 (`Microsoft.WindowsAppSDK 2.7.0`, unpackaged self-contained `WindowsPackageType=None`), Win32 `Shell_NotifyIcon`, `ITaskbarList3`, Named Pipe IPC (`PomoPet.IPC.v1`), `pomopet://` URI protocol
- **Shared Assets**: `shared/sprites.json` (16×16 pixel-art frames for `idle`, `focusing`, `stretching`, `napping`)
- **Tests**: Swift `PomoPetSelfTest` executable + `PomoPetCoreTests` (XCTest); .NET `PomoPet.Core.Tests`

## Repository Structure

```text
pomo-pet/
├── README.md                                  # Features, quick start, pomopet:// URI reference
├── shared/
│   └── sprites.json                           # Canonical 16×16 pixel-art sprite catalog (source of truth)
├── macos/
│   ├── Package.swift                          # Swift 6 package: PomoPetCore, PomoPet, PomoPetSelfTest, PomoPetCoreTests
│   ├── scripts/bundle-macos.sh                # Syncs shared/sprites.json, builds release, creates dist/PomoPet.app
│   ├── Sources/
│   │   ├── PomoPetCore/                       # Engine/PomodoroEngine.swift, Models/, Sprites/PixelSpriteCatalog.swift,
│   │   │                                      # Resources/sprites.json (synced copy)
│   │   ├── PomoPet/                           # App/ (PomoPetApp, AppDelegate, AnimationClock, BreakOverlayController),
│   │   │                                      # Rendering/PixelImageRenderer, Services/NotificationManager, Views/
│   │   └── PomoPetSelfTest/main.swift         # Standalone CLI verification runner
│   └── Tests/PomoPetCoreTests/                # PomodoroEngineTests.swift, PixelSpriteLoaderTests.swift
└── windows/
    ├── PomoPet.sln                            # Solution with Core, App, PowerToys, Core.Tests
    ├── src/
    │   ├── PomoPet.Core/                      # PomodoroEngine, Models, PixelSpriteCatalog, IpcProtocol (embeds shared/sprites.json)
    │   ├── PomoPet.App/                       # WinUI 3 app: App.xaml(.cs), Windows/ (MainWindow, FloatingPillWindow,
    │   │                                      # BreakOverlayWindow), Services/ (IpcServerService, TrayIconService,
    │   │                                      # TaskbarProgressService, ToastNotificationService, PixelBitmapRenderer)
    │   └── PomoPet.PowerToys/                 # PowerToys Command Palette companion (PomoPetIpcClient, PomoPetPaletteProvider)
    └── tests/PomoPet.Core.Tests/              # PomodoroEngineTests.cs
```

## Architecture & Key Flows

- **macOS Entry & Lifecycle**: `PomoPetApp.swift` boots `AppDelegate`, which owns the `NSStatusItem` (animated pixel pet + tabular countdown), `NSPopover` (`PopoverView` + `SettingsView`), `AnimationClock`, `PomodoroEngine`, `NotificationManager`, and multi-screen `BreakOverlayController` (`NSPanel` hosting `BreakOverlayView`).
- **Windows Entry & Lifecycle**: `PomoPet.App/App.xaml.cs` initializes `PomodoroEngine`, `MainWindow` (`MicaBackdrop`), docked always-on-top Acrylic `FloatingPillWindow`, `BreakOverlayWindow`, `TrayIconService` (`Shell_NotifyIcon`), `TaskbarProgressService` (`ITaskbarList3`), `ToastNotificationService`, and `IpcServerService` (Named Pipe `PomoPet.IPC.v1`).
- **PowerToys & URI Integration (Windows)**: `PomoPet.PowerToys` talks to the running app via `PomoPet.IPC.v1` named pipe and falls back to `pomopet://` URIs (`start`, `pause`, `toggle`, `break`, `snooze/5`, `skip`, `pet/cat|dog|capybara`).
- **Sprite Rendering**: Both `PixelImageRenderer.swift` and `PixelBitmapRenderer.cs` decode the shared 16×16 palette/frame grid from `sprites.json` into nearest-neighbor crisp bitmaps for menu bar/tray icons and UI previews.

## Development & Commands

```bash
# macOS — run self-test & unit tests
cd macos && swift run PomoPetSelfTest
cd macos && swift test

# macOS — sync sprites, build release binary, and bundle dist/PomoPet.app
cd macos && ./scripts/bundle-macos.sh
open macos/dist/PomoPet.app
```

```powershell
# Windows — run core & IPC/URI unit tests
dotnet test windows/tests/PomoPet.Core.Tests/PomoPet.Core.Tests.csproj

# Windows — build WinUI 3 app and PowerToys companion (x64 or ARM64)
dotnet build windows/src/PomoPet.App/PomoPet.App.csproj -c Release -p:Platform=x64
dotnet build windows/src/PomoPet.PowerToys/PomoPet.PowerToys.csproj -c Release -p:Platform=x64
```

## Configuration & Environment

- **No `.env` files or external APIs**: 100% local desktop apps.
- **macOS Bundle Metadata**: Generated by `macos/scripts/bundle-macos.sh` into `macos/dist/PomoPet.app/Contents/Info.plist` (`com.pomopet.app`, `LSUIElement = true`).
- **Windows Packaging**: Unpackaged self-contained WinUI 3 (`WindowsPackageType=None`, `WindowsAppSDKSelfContained=true`, `AllowUnsafeBlocks=true` for Win32 interop).

## Conventions & Gotchas

- **Sprite Syncing**: `shared/sprites.json` is the canonical asset. Windows embeds it directly via `<EmbeddedResource Include="..\..\..\shared\sprites.json" />`, whereas macOS uses a copy at `macos/Sources/PomoPetCore/Resources/sprites.json` synced by `bundle-macos.sh`. Always edit `shared/sprites.json` and re-copy before `swift test` / `swift run`.
- **Cross-Platform Engine Parity**: `PomodoroEngine.swift` and `PomodoroEngine.cs` are separate native implementations — keep timer states, cycle rules, and settings defaults aligned across both platforms.
- **Swift 6 Concurrency**: `macos/Package.swift` uses `swift-tools-version: 6.0` (strict concurrency checking); keep AppKit/SwiftUI UI updates isolated on `@MainActor`.
- **Windows Platform Argument**: Always pass `-p:Platform=x64` or `-p:Platform=ARM64` when building `PomoPet.App` or `PomoPet.PowerToys`.
