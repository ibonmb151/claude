import SwiftUI

@main
struct MymApp: App {
    @StateObject private var store = AppStore.shared
    @StateObject private var accountStore = AccountStore.shared
    #if os(macOS)
    @StateObject private var config = ConfigStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            MacRootView()
                .environmentObject(store)
                .environmentObject(accountStore)
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
        // ⌘,: configuración de cuentas, datos y seguridad.
        Settings {
            ConfigView()
                .environmentObject(config)
                .environmentObject(accountStore)
        }
        #else
        WindowGroup {
            PhoneRootView()
                .environmentObject(store)
                .environmentObject(accountStore)
        }
        #endif
    }
}
