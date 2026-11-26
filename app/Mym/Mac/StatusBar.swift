#if os(macOS)
import SwiftUI
import AppKit
import Combine

/// Icono en la barra de menús con el resultado del día y un panel desplegable.
/// Se hace con AppKit porque MenuBarExtra necesita macOS 13.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = AppStore.shared

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "chart.bar.xaxis", accessibilityDescription: "Mym")
            button.imagePosition = .imageLeft
            button.title = " " + Fmt.signedPct(store.data.dayPct, 2)
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        statusItem = item

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 380)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView().environmentObject(store)
        )

        cancellable = store.$data
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.statusItem?.button?.title = " " + Fmt.signedPct(snapshot.dayPct, 2)
            }
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
#endif
