import Foundation
import Testing
@testable import Suzuran

final class GeminiURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler else {
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("{}".utf8))
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

@Suite("GeminiSummaryService")
struct GeminiSummaryServiceTests {
    @Test("uses the current Gemini generateContent endpoint and redacts keys from logs")
    func usesOfficialRequestContract() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [GeminiURLProtocol.self]
        let session = URLSession(configuration: config)

        GeminiURLProtocol.handler = { request in
            #expect(request.url?.absoluteString.contains("generativelanguage.googleapis.com/v1beta") == true)
            #expect(request.url?.absoluteString.contains("generateContent") == true)
            #expect(request.url?.absoluteString.contains("v1beta2") == false)
            #expect(request.url?.query?.contains("key=test-key") == true)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            guard let body = request.httpBody else {
                throw NSError(domain: "GeminiSummaryServiceTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Request body missing"])
            }
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            #expect(json?["contents"] != nil)
            #expect(json?["systemInstruction"] != nil)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let payload = """
            {
              "candidates": [
                { "content": { "text": "Ringkasan kulitmu tampak stabil." } }
              ]
            }
            """
            return (response, Data(payload.utf8))
        }

        let service = GeminiSummaryService(
            apiKeyProvider: StubAPIKeyProvider(value: "test-key"),
            modelName: "gemini-2.5-flash",
            session: session
        )

        let records = [
            ScanRecord(
                date: Date().addingTimeInterval(-86400),
                frontImageData: nil,
                skinScore: 72,
                totalAcneCount: 10,
                severity: .moderate,
                acneTypeCounts: [
                    .init(acneType: .papule, count: 4),
                    .init(acneType: .blackhead, count: 6)
                ]
            ),
            ScanRecord(
                date: Date(),
                frontImageData: nil,
                skinScore: 74,
                totalAcneCount: 8,
                severity: .mild,
                acneTypeCounts: [
                    .init(acneType: .papule, count: 3),
                    .init(acneType: .blackhead, count: 5)
                ]
            )
        ]

        let result = try await service.generateSummary(for: records)
        #expect(result == "Ringkasan kulitmu tampak stabil.")
        #expect(LoggingHelpers.redactSensitive("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaabcdefghijklmnop")
            .contains("[REDACTED]"))
    }
}

private struct StubAPIKeyProvider: APIKeyProvider {
    let value: String
    func getAPIKey() -> String? { value }
}
