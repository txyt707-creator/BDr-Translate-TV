import Foundation
import Network

/// Independent HTTP subtitle source for ReplayKit. Runs in the broadcast
/// extension, not the suspended containing app. Local Wi-Fi only.
/// Prototype pairing: first valid six-digit TV PIN is bound for this broadcast.
final class BroadcastSubtitleServer {
    private let queue = DispatchQueue(label: "com.bdrtranslate.broadcast.http")
    private var listener: NWListener?
    private var pairedPIN: String?
    private var subtitle = ""
    private var revision = 0
    private(set) var status = "غير متصل"

    func start() {
        do {
            let port = NWEndpoint.Port(rawValue: 8766)!
            let listener = try NWListener(using: .tcp, on: port)
            listener.newConnectionHandler = { [weak self] connection in
                self?.receive(connection)
            }
            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready: self?.status = "جاهز للاتصال على المنفذ 8766"
                case .failed(let error): self?.status = "فشل الاتصال: \\(error)"
                default: break
                }
            }
            self.listener = listener
            listener.start(queue: queue)
        } catch {
            status = "فشل تشغيل خادم البث: \\(error.localizedDescription)"
        }
    }

    func update(_ text: String) {
        queue.async {
            let cleaned = String(text.prefix(300))
            guard cleaned != self.subtitle else { return }
            self.subtitle = cleaned
            self.revision += 1
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func receive(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, error in
            guard let self, error == nil, let data,
                  let request = String(data: data, encoding: .utf8),
                  let line = request.components(separatedBy: "\r\n").first else {
                connection.cancel()
                return
            }
            let parts = line.split(separator: " ")
            guard parts.count >= 2,
                  let url = URLComponents(string: "http://localhost" + String(parts[1])),
                  url.path == "/api/subtitle",
                  let pin = url.queryItems?.first(where: { $0.name == "pin" })?.value,
                  pin.count == 6, pin.allSatisfy({ $0.isNumber }) else {
                self.respond(connection, code: "400 Bad Request", payload: ["error":"invalid request"])
                return
            }
            self.queue.async {
                if self.pairedPIN == nil { self.pairedPIN = pin }
                guard self.pairedPIN == pin else {
                    self.respond(connection, code: "403 Forbidden", payload: ["error":"PIN mismatch"])
                    return
                }
                self.respond(connection, code: "200 OK", payload: [
                    "text": self.subtitle, "revision": self.revision
                ])
            }
        }
    }

    private func respond(_ connection: NWConnection, code: String, payload: [String: Any]) {
        let body = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data("{}".utf8)
        let header = "HTTP/1.1 \\(code)\r\nContent-Type: application/json; charset=utf-8\r\nCache-Control: no-store\r\nContent-Length: \\(body.count)\r\nConnection: close\r\n\r\n"
        var bytes = Data(header.utf8)
        bytes.append(body)
        connection.send(content: bytes, completion: .contentProcessed { _ in connection.cancel() })
    }
}
