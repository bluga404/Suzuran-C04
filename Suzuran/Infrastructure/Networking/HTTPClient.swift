import Foundation

protocol HTTPClient {
    func send(baseURL: URL, endpoint: Endpoint) async throws -> (Data, HTTPURLResponse)
}
