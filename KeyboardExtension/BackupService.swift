import Foundation

enum BackupService {

    struct Payload: Codable {
        let email: String
        let createdAt: String
        let entries: [String]
    }

    static func sendIfDue(completion: @escaping (Bool, String) -> Void) {
        guard KeyboardStorage.backupIsDue else {
            completion(false, "Backup ainda não venceu.")
            return
        }

        let endpoint = KeyboardStorage.endpointURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: endpoint), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            completion(false, "Configure um endpoint HTTP/HTTPS.")
            return
        }

        let payload = Payload(
            email: KeyboardStorage.backupEmail,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            entries: KeyboardStorage.history
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(false, "Falha ao criar o backup.")
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                completion(false, "Servidor recusou o backup.")
                return
            }

            KeyboardStorage.lastBackup = Date()
            completion(true, "Backup enviado.")
        }.resume()
    }
}
