import Foundation

struct Endpoint {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem]
    var headers: [String: String]
    var body: Data?

    init(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }
}
