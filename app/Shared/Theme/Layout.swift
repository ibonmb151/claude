import SwiftUI

/// Retícula de 8 puntos: todo el aire de la app sale de aquí.
enum Layout {
    /// Hueco entre tarjetas.
    static let gap: CGFloat = 24
    /// Relleno de una tarjeta grande y de una pequeña.
    static let card: CGFloat = 20
    static let cardSmall: CGFloat = 16
    /// Margen lateral de una pantalla.
    static let page: CGFloat = 32
    /// Dock lateral: ancho, botón e hueco entre botones.
    static let railWidth: CGFloat = 72
    static let railItem: CGFloat = 48
    static let railGap: CGFloat = 8
}
