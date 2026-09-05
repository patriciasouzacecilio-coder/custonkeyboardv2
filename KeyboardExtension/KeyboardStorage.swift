import Foundation

enum KeyboardStorage {
    private static let d = UserDefaults.standard

    static var historyEnabled: Bool {
        get { d.bool(forKey: "historyEnabled") }
        set { d.set(newValue, forKey: "historyEnabled") }
    }

    static var automaticBackupEnabled: Bool {
        get { d.bool(forKey: "automaticBackupEnabled") }
        set { d.set(newValue, forKey: "automaticBackupEnabled") }
    }

    static var themeIndex: Int {
        get { d.integer(forKey: "themeIndex") }
        set { d.set(newValue, forKey: "themeIndex") }
    }

    static var backupHours: Double {
        get {
            let v = d.double(forKey: "backupHours")
            return v == 0 ? 24 : v
        }
        set { d.set(newValue, forKey: "backupHours") }
    }

    static var backupEmail: String {
        get { d.string(forKey: "backupEmail") ?? "" }
        set { d.set(newValue, forKey: "backupEmail") }
    }

    static var endpointURL: String {
        get { d.string(forKey: "endpointURL") ?? "" }
        set { d.set(newValue, forKey: "endpointURL") }
    }

    static var lastBackup: Date? {
        get { d.object(forKey: "lastBackup") as? Date }
        set { d.set(newValue, forKey: "lastBackup") }
    }

    static var history: [String] {
        get { d.stringArray(forKey: "history") ?? [] }
        set { d.set(Array(newValue.suffix(5000)), forKey: "history") }
    }

    static func append(_ text: String) {
        guard historyEnabled, !text.isEmpty else { return }
        var items = history
        let stamp = ISO8601DateFormatter().string(from: Date())
        items.append("\(stamp)  \(text)")
        history = items
    }

    static func clearHistory() { history = [] }

    static var backupIsDue: Bool {
        guard automaticBackupEnabled, !history.isEmpty else { return false }
        guard let last = lastBackup else { return true }
        return Date().timeIntervalSince(last) >= backupHours * 3600
    }
}
