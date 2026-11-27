import SwiftUI
import Foundation

#if os(macOS)
import AppKit

/// Carpeta de datos (06_CONFIG). La app está en el sandbox: el permiso para leerla se guarda como marcador.
enum DataFolder {
    private static let key = "mym.dataFolderBookmark"

    static var isSet: Bool { UserDefaults.standard.data(forKey: key) != nil }

    /// Pide al usuario que elija la carpeta. Devuelve su nombre (solo el último tramo de la ruta).
    @discardableResult
    static func choose() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Elegir"
        panel.message = "Elige la carpeta con los ficheros de datos (06_CONFIG)"
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        guard let data = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) else { return nil }
        UserDefaults.standard.set(data, forKey: key)
        return url.lastPathComponent
    }

    static func forget() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    static var name: String? {
        resolve()?.lastPathComponent
    }

    private static func resolve() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        var stale = false
        return try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale)
    }

    /// Ejecuta `body` con permiso de lectura sobre la carpeta elegida.
    static func withAccess<T>(_ body: (URL) -> T) -> T? {
        guard let url = resolve() else { return nil }
        let granted: Bool = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        return body(url)
    }
}
#endif

/// Datos de las cuentas que ve toda la app. Demostración por defecto; en el Mac puede leer los JSON reales.
final class AccountStore: ObservableObject {
    static let shared = AccountStore()

    @Published var bundle: AccountBundle = .demo
    @Published var scope: AccountScope = .all
    @Published var useDemo: Bool {
        didSet {
            UserDefaults.standard.set(useDemo, forKey: "mym.demo")
            reload()
        }
    }
    @Published var folderName: String?

    private var timer: Timer?

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "mym.demo") == nil { defaults.set(true, forKey: "mym.demo") }
        useDemo = defaults.bool(forKey: "mym.demo")
        #if os(macOS)
        folderName = DataFolder.name
        #endif
        reload()
        // Se refresca cada 5 minutos.
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.reload()
        }
    }

    #if os(macOS)
    func chooseFolder() {
        if let name = DataFolder.choose() {
            folderName = name
            useDemo = false
        }
    }
    #endif

    func reload() {
        #if os(macOS)
        if !useDemo {
            if let loaded = Self.loadFromFolder() {
                bundle = loaded
                return
            }
        }
        #endif
        bundle = .demo
    }

    // MARK: Lectura de los JSON

    #if os(macOS)
    private static func loadFromFolder() -> AccountBundle? {
        DataFolder.withAccess { folder -> AccountBundle in
            var b = AccountBundle()
            b.source = .files
            b.loadedAt = Date()
            b.accounts = read("cuentas_metricas.json", in: folder, into: &b.files)
            b.modules = read("modulos_metricas.json", in: folder, into: &b.files)
            b.daily = read("metricas_diarias.json", in: folder, into: &b.files)
            b.curve = read("curva_equity.json", in: folder, into: &b.files)
            b.trades = read("seq_labels.json", in: folder, into: &b.files)
            return b
        }
    }

    private static func read<T: Decodable>(_ name: String, in folder: URL, into files: inout [FileStatus]) -> [T] {
        let url = folder.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else {
            files.append(FileStatus(name: name, state: .missing, modified: nil))
            return []
        }
        let modified: Date? = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        guard let data = try? Data(contentsOf: url) else {
            files.append(FileStatus(name: name, state: .invalid, modified: modified))
            return []
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let items = try? decoder.decode([T].self, from: data) else {
            files.append(FileStatus(name: name, state: .invalid, modified: modified))
            return []
        }
        files.append(FileStatus(name: name, state: .ok, modified: modified))
        return items
    }
    #endif
}
