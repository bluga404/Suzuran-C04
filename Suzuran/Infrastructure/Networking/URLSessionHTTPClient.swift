import Foundation

struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send(baseURL: URL, endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        let request = try makeRequest(baseURL: baseURL, endpoint: endpoint)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.unknown(message: "Non-HTTP response received")
        }

        return (data, httpResponse)
    }

    private func makeRequest(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw AppError.validation(message: "Invalid endpoint path")
        }

        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw AppError.validation(message: "Invalid endpoint URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body

        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}
