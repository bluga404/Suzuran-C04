import Foundation

final class GeminiSummaryService: SummaryServiceProtocol {
    private let apiKeyProvider: APIKeyProvider
    private let modelName: String
    private let baseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta")!
    private let session: URLSession
    private let logger: AppLogging

    init(
        apiKeyProvider: APIKeyProvider = KeychainAPIKeyProvider(),
        modelName: String = "gemini-3.6-flash",
        session: URLSession = .shared,
        logger: AppLogging = AppLogger()
    ) {
        self.apiKeyProvider = apiKeyProvider
        self.modelName = modelName
        self.session = session
        self.logger = logger
    }

    func generateSummary(for records: [ScanRecord]) async throws -> String {
        guard !records.isEmpty else { return "" }
        guard let apiKey = apiKeyProvider.getAPIKey(), !apiKey.isEmpty else {
            logger.error("Gemini API key missing in Keychain; aborting summary generation", file: #fileID, line: #line)
            throw AppError.validation(message: "Missing Gemini API key. Provide a key via Keychain or App configuration.")
        }

        logger.info("Preparing Gemini summary request (model=\(modelName), records=\(records.count))", file: #fileID, line: #line)

        let request = try createRequest(for: records, apiKey: apiKey)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.unknown(message: "Invalid response from Gemini API.")
        }

        switch httpResponse.statusCode {
        case 200..<300:
            logger.info("Gemini request succeeded (\(httpResponse.statusCode))", file: #fileID, line: #line)
        case 401:
            logger.error("Gemini unauthorized (401)", file: #fileID, line: #line)
            throw AppError.unauthorized
        case 403:
            logger.error("Gemini forbidden (403)", file: #fileID, line: #line)
            throw AppError.forbidden
        case 404:
            logger.error("Gemini not found (404)", file: #fileID, line: #line)
            throw AppError.notFound
        default:
            let body = String(data: data, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            logger.error("Gemini request failed (\(httpResponse.statusCode)): \(LoggingHelpers.redactSensitive(body))", file: #fileID, line: #line)
            throw AppError.server(message: "Gemini request failed. Please try again later.")
        }

        do {
            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
            let candidateText = decoded.candidates?
                .compactMap { candidate in
                    candidate.content?.parts?
                        .compactMap(\.text)
                        .joined(separator: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            guard let text = candidateText, !text.isEmpty else {
                logger.error("Gemini response decoded but contained no text", file: #fileID, line: #line)
                throw AppError.decoding
            }

            let sanitized = sanitizeResponse(text)
            logger.info("Gemini produced summary (\(sanitized.count) chars)", file: #fileID, line: #line)
            return sanitized
        } catch {
            logger.error("Failed decoding Gemini response: \(error.localizedDescription)", file: #fileID, line: #line)
            throw error
        }
    }

    private func createRequest(for records: [ScanRecord], apiKey: String) throws -> URLRequest {
        let modelPath = "models/\(modelName):generateContent"
        let url = baseURL.appendingPathComponent(modelPath)

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        guard let finalURL = components?.url else {
            throw AppError.validation(message: "Invalid Gemini API URL")
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let payload = GenerateContentRequest(
            contents: [GenerateContentRequest.Content(parts: [.init(text: buildPrompt(for: records))])],
            systemInstructionText: buildSystemInstruction()
        )
        request.httpBody = try JSONEncoder().encode(payload)

        logger.info("Prepared Gemini request URL=\(LoggingHelpers.redactSensitive(finalURL.absoluteString)) payloadLength=\(String(describing: try? JSONEncoder().encode(payload).count))", file: #fileID, line: #line)

        return request
    }

    private func buildPrompt(for records: [ScanRecord]) -> String {
        let sorted = records.sorted { $0.date < $1.date }
        let first = sorted.first!
        let latest = sorted.last!

        let firstDate = DateFormatters.fullDateID.string(from: first.date)
        let latestDate = DateFormatters.fullDateID.string(from: latest.date)

        let firstDominant = first.acneTypeCounts.max(by: { $0.count < $1.count })?.acneType.displayName.lowercased() ?? "acne"
        let latestDominant = latest.acneTypeCounts.max(by: { $0.count < $1.count })?.acneType.displayName.lowercased() ?? "acne"
        let acneDelta = latest.totalAcneCount - first.totalAcneCount
        let acneDirection = acneDelta < 0 ? "decreased" : acneDelta > 0 ? "increased" : "stayed stable"
        let scoreDelta = latest.skinScore - first.skinScore
        let scoreTrend = scoreDelta < 0 ? "declined" : scoreDelta > 0 ? "improved" : "remained stable"

        let latestTypeBreakdown = latest.acneTypeCounts
            .filter { $0.count > 0 }
            .map { "- \($0.acneType.displayName): \($0.count)" }
            .joined(separator: "\n")

        let prompt = """
        Based on the face-scan history below, write one short paragraph in clear English.
        Focus on the main trend: whether the skin is improving, worsening, or staying stable. Mention the acne type that is most common right now in simple language.
        Do not use technical jargon. Do not provide medical diagnosis. Do not make overstated claims. If the data is limited, say the data is still limited.
        Output must be a short paragraph of 2-4 sentences, with no bullet points, no markdown, and no extra sections.

        Scan data:
        - First scan (\(firstDate)): skin score \(first.skinScore), total acne \(first.totalAcneCount), dominant acne type \(firstDominant).
        - Latest scan (\(latestDate)): skin score \(latest.skinScore), total acne \(latest.totalAcneCount), dominant acne type \(latestDominant).
        - Comparison: acne count \(acneDirection) by \(abs(acneDelta)) and skin score \(scoreTrend).
        - Latest acne breakdown:
        \(latestTypeBreakdown)
        """

        return prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildSystemInstruction() -> String {
        """
        You help users understand their facial scan results.
        Write in simple, friendly English.
        Focus on the main trend that is clearly supported by the data.
        Avoid technical medical terms and do not provide medical advice.
        Return only one short paragraph suitable for a general user.
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
            let parts: [Part]?

            struct Part: Decodable {
                let text: String?
            }
        }
    }
}
