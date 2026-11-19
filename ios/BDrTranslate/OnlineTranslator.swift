import Foundation

/// Prototype network translation. MyMemory's public endpoint is rate-limited and
/// may log submitted text. Replace with a private service before commercial use.
enum OnlineTranslator {
    enum TranslationError: LocalizedError {
        case invalidURL, badResponse, emptyTranslation, serviceError(String)
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "تعذر إعداد رابط خدمة الترجمة"
            case .badResponse: return "لم يستجب سيرفر الترجمة بشكل صحيح"
            case .emptyTranslation: return "رجعت الترجمة فارغة"
            case .serviceError(let message): return message
            }
        }
    }

    private struct Response: Decodable {
        struct ResponseData: Decodable {
            let translatedText: String
        }
        let responseData: ResponseData
        let responseStatus: Int?
        let responseDetails: String?
    }

    static func translate(_ text: String) async throws -> String {
        let input = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(450))
        guard var parts = URLComponents(string: "https://api.mymemory.translated.net/get") else {
            throw TranslationError.invalidURL
        }
        parts.queryItems = [
            URLQueryItem(name: "q", value: input),
            URLQueryItem(name: "langpair", value: "en|ar")
        ]
        guard let url = parts.url else { throw TranslationError.invalidURL }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("BDrTranslate/0.3 (prototype)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TranslationError.badResponse
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard decoded.responseStatus == nil || decoded.responseStatus == 200 else {
            throw TranslationError.serviceError(decoded.responseDetails ?? "خدمة الترجمة غير متاحة")
        }
        let translated = decoded.responseData.translatedText
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !translated.isEmpty else { throw TranslationError.emptyTranslation }
        return translated
    }
}
