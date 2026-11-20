import AppKit
import Combine
import PomoPetCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let engine = PomodoroEngine()
    let catalog: PixelSpriteCatalog

    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let overlayController = BreakOverlayController()
    private let animationClock = AnimationClock()
    private var timerCancellable: AnyCancellable?
    private var animationCancellable: AnyCancellable?
    private var engineCancellable: AnyCancellable?

    override init() {
        self.catalog = (try? PixelSpriteCatalog.loadBundled()) ?? PixelSpriteCatalog(sheets: [:])
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NotificationManager.shared.requestAuthorizationIfAvailable()

        setupPopover()
        setupStatusItem()
        bindEngineCallbacks()
        startTimers()
        updateStatusItem()
    }

    private func setupPopover() {
        popover.behavior = .transient
        popover.animates = true
        let rootView = PopoverView(
            engine: engine,
            catalog: catalog,
            clock: animationClock
        )
        popover.contentViewController = NSHostingController(rootView: rootView)
        popover.contentSize = NSSize(width: 320, height: 430)
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.imagePosition = .imageLeading
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .medium)
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
    }

    private func bindEngineCallbacks() {
        engine.onBreakStarted = { [weak self] phase, prompt in
            guard let self else { return }
            NotificationManager.shared.notifyBreakStarted(
                phase: phase,
                prompt: prompt,
                playSound: self.engine.settings.playSoundChime
            )
            if self.engine.isBreakOverlayPresented {
                self.popover.performClose(nil)
                self.overlayController.show(
                    engine: self.engine,
                    catalog: self.catalog,
                    clock: self.animationClock
                )
            }
        }

        engine.onFocusStarted = { [weak self] in
            guard let self else { return }
            self.overlayController.dismiss(animated: true)
            NotificationManager.shared.notifyFocusReady(playSound: self.engine.settings.playSoundChime)
        }

        engine.onOverlayDismissed = { [weak self] in
            self?.overlayController.dismiss(animated: true)
        }

        engineCancellable = engine.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItem()
            }
        }
    }

    private func startTimers() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.engine.tick(now: now)
                self?.updateStatusItem()
            }

        animationCancellable = Timer.publish(every: 0.45, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.animationClock.tick &+= 1
                self.animationClock.bobbing.toggle()
                if self.animationClock.tick % 8 == 0 {
                    self.animationClock.isInhaling.toggle()
                }
                self.updateStatusItem()
            }
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }
        if let frame = catalog.frame(
            for: engine.settings.selectedPet,
            state: engine.petAnimationState,
            tick: animationClock.tick
        ) {
            button.image = PixelImageRenderer.menuBarImage(from: frame, pointSize: 18)
        }

        if engine.settings.showTimerInMenuBar {
            button.title = " \(engine.formattedTime)"
        } else {
            button.title = ""
        }

        button.toolTip = "PomoPet • \(engine.phase.title) (\(engine.formattedTime)) — \(engine.statusSubtitle)"
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
