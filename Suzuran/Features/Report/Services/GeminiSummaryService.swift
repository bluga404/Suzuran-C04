import Foundation

final class GeminiSummaryService {
    private let apiKey: String?
    private let modelName: String
    private let baseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta")!

    init(
        apiKey: String? = Bundle.main.object(forInfoDictionaryKey: AppConstants.geminiApiKeyInfoPlistKey) as? String,
        modelName: String = "gemini-3.6-flash"
    ) {
        self.apiKey = apiKey
        self.modelName = modelName
    }

    func generateSummary(for records: [ScanRecord]) async throws -> String {
        guard !records.isEmpty else {
            return ""
        }

        guard let apiKey else {
            throw AppError.validation(message: "Missing Gemini API key. Set the GeminiAPIKey value in Info.plist.")
        }

        let request = try createRequest(for: records, apiKey: apiKey)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.unknown(message: "Invalid response from Gemini API.")
        }

        switch httpResponse.statusCode {
        case 200..<300:
            break
        case 401:
            throw AppError.unauthorized
        case 403:
            throw AppError.forbidden
        case 404:
            throw AppError.notFound
        default:
            let body = String(data: data, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw AppError.server(message: "Gemini request failed (\(httpResponse.statusCode)): \(body)")
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = decoded.candidates?.first?.content?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            throw AppError.decoding
        }

        return sanitizeResponse(text)
    }

    private func createRequest(for records: [ScanRecord], apiKey: String) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("models/")
            .appendingPathComponent(modelName)
            .appendingPathComponent(":generateContent")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = GenerateContentRequest(
            contents: [GenerateContentRequest.Content(parts: [.init(text: buildPrompt(for: records))])],
            systemInstructionText: buildSystemInstruction()
        )
        request.httpBody = try JSONEncoder().encode(payload)

        return request
    }

    private func buildPrompt(for records: [ScanRecord]) -> String {
        let sorted = records.sorted { $0.date < $1.date }
        let first = sorted.first!
        let latest = sorted.last!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "d MMM yyyy"

        let firstDate = formatter.string(from: first.date)
        let latestDate = formatter.string(from: latest.date)

        let firstDominant = first.acneTypeCounts.max(by: { $0.count < $1.count })?.acneType.displayName.lowercased() ?? "jerawat"
        let latestDominant = latest.acneTypeCounts.max(by: { $0.count < $1.count })?.acneType.displayName.lowercased() ?? "jerawat"
        let acneDelta = latest.totalAcneCount - first.totalAcneCount
        let acneDirection = acneDelta < 0 ? "berkurang" : acneDelta > 0 ? "bertambah" : "tetap"
        let scoreDelta = latest.skinScore - first.skinScore
        let scoreTrend = scoreDelta < 0 ? "menurun" : scoreDelta > 0 ? "meningkat" : "stabil"

        let latestTypeBreakdown = latest.acneTypeCounts
            .filter { $0.count > 0 }
            .map { "- \($0.acneType.displayName): \($0.count)" }
            .joined(separator: "\n")

        let prompt = """
        Berdasarkan data riwayat scan wajah berikut, tulis satu paragraf singkat dalam bahasa Indonesia yang mudah dipahami.
        Fokus pada tren utama: apakah kondisi kulitmu membaik, memburuk, atau tetap stabil. Sebutkan jenis jerawat yang paling sering muncul saat ini dengan bahasa sederhana.
        Jangan memakai istilah teknis yang rumit. Jangan memberi diagnosis medis. Jangan membuat klaim yang terlalu kuat. Jika datanya terbatas, sebutkan bahwa data masih terbatas.
        Hasilnya harus berupa satu paragraf pendek, 2-4 kalimat, tanpa bullet, tanpa markdown, dan tanpa menambahkan bagian lain.

        Data scan:
        - Scan pertama (\(firstDate)): skor kulit \(first.skinScore), total jerawat \(first.totalAcneCount), jenis jerawat dominan \(firstDominant).
        - Scan terakhir (\(latestDate)): skor kulit \(latest.skinScore), total jerawat \(latest.totalAcneCount), jenis jerawat dominan \(latestDominant).
        - Perbandingan: jumlah jerawat \(acneDirection) \(abs(acneDelta)) dan skor kulit \(scoreTrend).
        - Rincian jenis jerawat terbaru:
        \(latestTypeBreakdown)
        """

        return prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildSystemInstruction() -> String {
        """
        Kamu adalah asisten yang membantu pengguna memahami hasil scan wajah mereka.
        Tulis jawaban dalam bahasa Indonesia yang sederhana, jelas, dan ramah.
        Fokus pada tren utama yang benar-benar terlihat dari data.
        Hindari istilah medis yang rumit dan jangan memberi saran medis.
        Balas hanya dengan satu paragraf pendek yang mudah dipahami oleh pengguna umum.
        """
    }

    private func sanitizeResponse(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutMarkdown = trimmed
            .replacingOccurrences(of: #"^\s*[-*]\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\*\*|```"#, with: "", options: .regularExpression)
        return withoutMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct GenerateContentRequest: Encodable {
    struct Content: Encodable {
        struct Part: Encodable {
            let text: String
        }

        let parts: [Part]
    }

    let contents: [Content]
    let generationConfig: GenerationConfig
    let systemInstruction: SystemInstruction

    init(contents: [Content], systemInstructionText: String) {
        self.contents = contents
        self.generationConfig = GenerationConfig(
            temperature: 0.35,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 220
        )
        self.systemInstruction = SystemInstruction(parts: [SystemInstruction.Part(text: systemInstructionText)])
    }
}

private struct GenerationConfig: Encodable {
    let temperature: Double
    let topP: Double
    let topK: Int
    let maxOutputTokens: Int
}

private struct SystemInstruction: Encodable {
    struct Part: Encodable {
        let text: String
    }

    let parts: [Part]
}

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]?

    struct Candidate: Decodable {
        let content: CandidateContent?

        struct CandidateContent: Decodable {
            let text: String?
        }
    }
}
