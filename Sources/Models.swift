import Foundation

struct Movie: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let originName: String
    let slug: String
    let posterPath: String
    let thumbPath: String
    let year: Int?
    let quality: String?
    let episodeCurrent: String?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, year, quality
        case originName = "origin_name"
        case posterPath = "poster_url"
        case thumbPath = "thumb_url"
        case episodeCurrent = "episode_current"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Chưa có tên"
        slug = try c.decodeIfPresent(String.self, forKey: .slug) ?? UUID().uuidString
        id = (try c.decodeIfPresent(String.self, forKey: .id)) ?? slug
        originName = try c.decodeIfPresent(String.self, forKey: .originName) ?? ""
        posterPath = try c.decodeIfPresent(String.self, forKey: .posterPath) ?? ""
        thumbPath = try c.decodeIfPresent(String.self, forKey: .thumbPath) ?? posterPath
        year = try c.decodeIfPresent(Int.self, forKey: .year)
        quality = try c.decodeIfPresent(String.self, forKey: .quality)
        episodeCurrent = try c.decodeIfPresent(String.self, forKey: .episodeCurrent)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(originName, forKey: .originName)
        try c.encode(slug, forKey: .slug)
        try c.encode(posterPath, forKey: .posterPath)
        try c.encode(thumbPath, forKey: .thumbPath)
        try c.encodeIfPresent(year, forKey: .year)
        try c.encodeIfPresent(quality, forKey: .quality)
        try c.encodeIfPresent(episodeCurrent, forKey: .episodeCurrent)
    }

    var posterURL: URL? { Self.imageURL(posterPath) }
    var backdropURL: URL? { Self.imageURL(thumbPath) }

    private static func imageURL(_ path: String) -> URL? {
        guard !path.isEmpty else { return nil }
        if let url = URL(string: path), url.scheme != nil { return url }
        return URL(string: "https://phimimg.com/" + path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
}

struct MovieListResponse: Decodable {
    struct DataPayload: Decodable {
        let items: [Movie]?
    }
    let data: DataPayload?
    let items: [Movie]?
    var movies: [Movie] { data?.items ?? items ?? [] }
}

struct MovieDetailResponse: Decodable {
    let movie: Movie?
    let episodes: [EpisodeServer]?
}

struct EpisodeServer: Decodable, Identifiable {
    let serverName: String
    let serverData: [Episode]
    var id: String { serverName }

    enum CodingKeys: String, CodingKey {
        case serverName = "server_name"
        case serverData = "server_data"
    }
}

struct Episode: Decodable, Identifiable {
    let name: String
    let link: String
    let linkM3U8: String?
    var id: String { name + link }

    enum CodingKeys: String, CodingKey {
        case name
        case link
        case linkM3U8 = "link_m3u8"
    }

    var playableURL: URL? {
        URL(string: linkM3U8?.isEmpty == false ? linkM3U8! : link)
    }
}
