import Foundation

/// Formato a la española: coma decimal, punto de millares y signo menos tipográfico.
enum Fmt {
    private static let moneyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "es_ES")
        f.usesGroupingSeparator = true
        f.groupingSeparator = "."
        f.decimalSeparator = ","
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f
    }()

    static func eur(_ value: Double) -> String {
        let s = moneyFormatter.string(from: NSNumber(value: value.rounded())) ?? "\(Int(value))"
        return s.replacingOccurrences(of: "-", with: "−") + " €"
    }

    static func eurDecimals(_ value: Double) -> String {
        let sign = value < 0 ? "−" : "+"
        return sign + comma(abs(value), 2) + " €"
    }

    /// 1,5 → "1,5". Sin signo.
    static func comma(_ value: Double, _ decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f", value).replacingOccurrences(of: ".", with: ",")
    }

    /// −0,31 % o +0,4 %. Con signo explícito.
    static func signedPct(_ value: Double, _ decimals: Int = 1) -> String {
        if abs(value) < 0.0000001 { return comma(0, decimals) + " %" }
        let sign = value < 0 ? "−" : "+"
        return sign + comma(abs(value), decimals) + " %"
    }

    /// 47 % — sin signo.
    static func pct(_ value: Double, _ decimals: Int = 0) -> String {
        comma(value, decimals) + " %"
    }

    static func lots(_ value: Double) -> String {
        comma(value, 2) + " lotes"
    }

    static func ms(_ value: Int) -> String { "\(value) ms" }

    static func price(_ value: Double) -> String { comma(value, 5) }
}
