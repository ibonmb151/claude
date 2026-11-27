import SwiftUI

@main
struct MymApp: App {
    @StateObject private var store = AppStore.shared
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            MacRootView()
                .environmentObject(store)
                .frame(minWidth: 1040, minHeight: 680)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Ir a") {
                ForEach(Array(Module.allCases.enumerated()), id: \.element.id) { index, module in
                    Button(module.title) { store.module = module }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
            }
            CommandGroup(after: .textEditing) {
                Button("Buscar y actuar…") { store.showSearch = true }
                    .keyboardShortcut("k", modifiers: .command)
            }
        }
        #else
        WindowGroup {
            PhoneRootView()
                .environmentObject(store)
        }
        #endif
    }
}
