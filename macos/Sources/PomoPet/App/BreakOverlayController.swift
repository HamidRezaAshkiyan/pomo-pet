import AppKit
import PomoPetCore
import SwiftUI

@MainActor
final class BreakOverlayController {
    private var windows: [NSWindow] = []
    private var keyMonitor: Any?

    func show(
        engine: PomodoroEngine,
        catalog: PixelSpriteCatalog,
        clock: AnimationClock
    ) {
        dismiss(animated: false)

        for screen in NSScreen.screens {
            let panel = OverlayPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .screenSaver
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.ignoresMouseEvents = false

            let rootView = BreakOverlayView(
                engine: engine,
                catalog: catalog,
                clock: clock
            )
            panel.contentView = NSHostingView(rootView: rootView)
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            windows.append(panel)
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            for window in windows {
                window.animator().alphaValue = 1
            }
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak engine] event in
            if event.keyCode == 53 { // Escape
                Task { @MainActor in
                    engine?.dismissOverlayOnly()
                }
                return nil
            }
            return event
        }
    }

    func dismiss(animated: Bool = true) {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }

        let currentWindows = windows
        windows = []
        guard !currentWindows.isEmpty else { return }

        if animated {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.25
                for window in currentWindows {
                    window.animator().alphaValue = 0
                }
            }, completionHandler: {
                Task { @MainActor in
                    for window in currentWindows {
                        window.orderOut(nil)
                    }
                }
            })
        } else {
            for window in currentWindows {
                window.orderOut(nil)
            }
        }
    }
}

private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
