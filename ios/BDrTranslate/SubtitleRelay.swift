import Foundation
import Network
import UIKit
import Darwin

final class SubtitleRelay: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var status = "غير متصل"
    @Published private(set) var deviceIP = "غير معروف"

    private var server: NWListener?
    private var generation = 0
    private let queue = DispatchQueue(label: "com.bdrtranslate.relay")
    private var pin = ""
    private var text = ""
    private var revision = 0

    func start(pin newPIN: String) {
        guard newPIN.count == 6 && newPIN.allSatisfy({ $0.isNumber }) else {
            status = "الرمز يجب أن يتكون من 6 أرقام"
            return
        }
        // The PIN field can emit repeated six-digit updates. Never rebind the same port.
        if pin == newPIN && server != nil { return }
        generation += 1
        let currentGeneration = generation
        let oldServer = server
        server = nil
        oldServer?.cancel()
        isRunning = false
        pin = newPIN
        text = ""
        revision = 0

        do {
            let listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: 8765)!)
            listener.newConnectionHandler = { [weak self] connection in
                self?.receive(connection)
            }
            listener.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    guard self?.generation == currentGeneration else { return }
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        self?.deviceIP = Self.localIPv4() ?? "افحص عنوان Wi-Fi"
                        self?.status = "جاهز — بانتظار التلفزيون"
                    case .failed(let error):
                        self?.server = nil
                        self?.isRunning = false
                        self?.status = "تعذّر تشغيل الاتصال: \(error.localizedDescription)"
                    case .cancelled:
                        break
                    default:
                        break
                    }
                }
            }
            server = listener
            listener.start(queue: queue)
        } catch {
            status = "خطأ الاتصال: \(error.localizedDescription)"
        }
    }

    func send(_ subtitle: String) {
        guard isRunning else { return }
        text = String(subtitle.prefix(300))
        revision += 1
        status = text.isEmpty ? "تم مسح الترجمة" : "تم تحديث الترجمة — \(revision)"
    }

    private func receive(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] bytes, _, _, error in
            guard let self = self else { connection.cancel(); return }
            guard error == nil, let bytes = bytes,
                  let request = String(data: bytes, encoding: .utf8),
                  let first = request.components(separatedBy: "\r\n").first else {
                connection.cancel()
                return
            }
            let components = first.split(separator: " ")
            guard components.count >= 2,
                  let url = URLComponents(string: "http://localhost" + String(components[1])) else {
                self.respond(connection, status: "400 Bad Request", body: ["error":"bad request"])
                return
            }
            let receivedPIN = url.queryItems?.first(where: { $0.name == "pin" })?.value ?? ""
            DispatchQueue.main.async {
                guard receivedPIN == self.pin else {
                    self.respond(connection, status: "403 Forbidden", body: ["error":"pairing mismatch"])
                    return
                }
                guard url.path == "/api/subtitle" else {
                    self.respond(connection, status: "404 Not Found", body: ["error":"not found"])
                    return
                }
                self.respond(connection, status: "200 OK", body: [
                    "text": self.text,
                    "revision": self.revision
                ])
            }
        }
    }

    private func respond(_ connection: NWConnection, status: String, body: [String: Any]) {
        let data = (try? JSONSerialization.data(withJSONObject: body)) ?? Data("{}".utf8)
        let headers = "HTTP/1.1 \(status)\r\nContent-Type: application/json; charset=utf-8\r\nAccess-Control-Allow-Origin: *\r\nCache-Control: no-store\r\nContent-Length: \(data.count)\r\nConnection: close\r\n\r\n"
        var response = Data(headers.utf8)
        response.append(data)
        connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
    }

    private static func localIPv4() -> String? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let first = interfaces else { return nil }
        defer { freeifaddrs(interfaces) }
        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let item = pointer {
            let info = item.pointee
            if let address = info.ifa_addr, address.pointee.sa_family == UInt8(AF_INET),
               String(cString: info.ifa_name) == "en0" {
                var copy = sockaddr_in()
                memcpy(&copy, address, MemoryLayout<sockaddr_in>.size)
                var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                let ipv4 = withUnsafePointer(to: &copy.sin_addr) {
                    $0.withMemoryRebound(to: UInt8.self, capacity: 4) { inet_ntop(AF_INET, $0, &buffer, socklen_t(INET_ADDRSTRLEN)) }
                }
                if ipv4 != nil { return String(cString: buffer) }
            }
            pointer = info.ifa_next
        }
        return nil
    }
}
