import Foundation

enum PhimAPIError: LocalizedError {
    case invalidResponse
    case server(String)
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Dữ liệu máy chủ không hợp lệ."
        case .server(let message): return message
        }
    }
}

final class PhimAPI {
    static let shared = PhimAPI()
    private let baseURL = URL(string: "https://phimapi.com")!
    private let decoder = JSONDecoder()

    private init() {}

    func latest(page: Int = 1) async throws -> [Movie] {
        let url = baseURL.appendingPathComponent("danh-sach/phim-moi-cap-nhat")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "page", value: String(page))]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try validate(response, data: data)
        return try decoder.decode(MovieListResponse.self, from: data).movies
    }

    func search(keyword: String) async throws -> [Movie] {
        var components = URLComponents(url: baseURL.appendingPathComponent("v1/api/tim-kiem"))!
        components.queryItems = [
            URLQueryItem(name: "keyword", value: keyword),
            URLQueryItem(name: "limit", value: "24")
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try validate(response, data: data)
        return try decoder.decode(MovieListResponse.self, from: data).movies
    }

    func detail(slug: String) async throws -> MovieDetailResponse {
        let url = baseURL.appendingPathComponent("phim").appendingPathComponent(slug)
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response, data: data)
        return try decoder.decode(MovieDetailResponse.self, from: data)
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw PhimAPIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            throw PhimAPIError.server("Máy chủ trả về lỗi HTTP \(http.statusCode).")
        }
    }
}
