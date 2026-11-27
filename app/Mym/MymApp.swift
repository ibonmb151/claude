import SwiftUI

@main
struct MymApp: App {
    @StateObject private var store = AppStore.shared
    @StateObject private var accountStore = AccountStore.shared
    @StateObject private var plan = PlanStore.shared
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
                .environmentObject(plan)
                .frame(minWidth: 1040, minHeight: 680)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Ir a") {
                ForEach(Array(Module.allCases.prefix(9).enumerated()), id: \.element.id) { index, module in
                    Button(module.title) { store.module = module }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
                ForEach(Array(Module.allCases.dropFirst(9))) { module in
                    Button(module.title) { store.module = module }
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
                .environmentObject(plan)
        }
        #endif
    }
}
