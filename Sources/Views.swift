import SwiftUI
import AVKit

private enum BomTheme {
    static let background = Color(red: 0.035, green: 0.035, blue: 0.045)
    static let panel = Color(red: 0.105, green: 0.105, blue: 0.12)
    static let red = Color(red: 0.9, green: 0.04, blue: 0.09)
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Trang chủ", systemImage: "house.fill") }
            SearchView()
                .tabItem { Label("Tìm kiếm", systemImage: "magnifyingglass") }
            LibraryView()
                .tabItem { Label("Thư viện", systemImage: "bookmark.fill") }
            AppSettingsView()
                .tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
                .tabItem { Label("Thư viện", systemImage: "bookmark.fill") }
        }
        .tint(BomTheme.red)
        .background(BomTheme.background)
    }
}

struct HomeView: View {
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if let featured = movies.first {
                        FeaturedMovieView(movie: featured)
                    }
                    HStack {
                        Text("Mới cập nhật").font(.title2.bold())
                        Spacer()
                        Text("PHIMAPI").font(.caption2.bold()).foregroundStyle(.secondary)
                    }.padding(.horizontal)
                    if isLoading && movies.isEmpty {
                        ProgressView("Đang tải phim…").frame(maxWidth: .infinity).padding(40)
                    } else if let errorMessage, movies.isEmpty {
                        EmptyStateView(title: "Chưa tải được phim", symbol: "wifi.exclamationmark", message: errorMessage)
                            .padding()
                        Button("Thử lại") { Task { await loadMovies() } }
                            .buttonStyle(.borderedProminent).tint(BomTheme.red)
                    } else {
                        MovieGrid(movies: movies)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(BomTheme.background)
            .toolbar(.hidden, for: .navigationBar)
            .task { if movies.isEmpty { await loadMovies() } }
            .refreshable { await loadMovies() }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("BOM").font(.system(size: 29, weight: .black, design: .rounded)).foregroundStyle(BomTheme.red)
                Text("PHIM").font(.system(size: 12, weight: .heavy, design: .rounded)).tracking(5)
            }
            Spacer()
            Image(systemName: "person.crop.circle").font(.title2).foregroundStyle(.white.opacity(0.85))
        }.padding(.horizontal).padding(.top, 12)
    }

    private func loadMovies() async {
        isLoading = true
        defer { isLoading = false }
        do {
            movies = try await PhimAPI.shared.latest()
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}

struct FeaturedMovieView: View {
    let movie: Movie
    var body: some View {
        NavigationLink(value: movie) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: movie.backdropURL) { phase in
                    if let image = phase.image { image.resizable().scaledToFill() }
                    else { Rectangle().fill(BomTheme.panel).overlay(Image(systemName: "film").font(.largeTitle).foregroundStyle(.gray)) }
                }
                .frame(height: 330).clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.92)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 9) {
                    Text("ĐỀ XUẤT HÔM NAY").font(.caption.bold()).tracking(2).foregroundStyle(BomTheme.red)
                    Text(movie.name).font(.largeTitle.bold()).lineLimit(2)
                    HStack(spacing: 10) {
                        Label(movie.year.map(String.init) ?? "Mới", systemImage: "calendar")
                        if let quality = movie.quality { Text(quality) }
                    }.font(.caption).foregroundStyle(.white.opacity(0.75))
                    Label("Xem chi tiết", systemImage: "play.fill").font(.subheadline.bold())
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(BomTheme.red, in: Capsule())
                }.padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .navigationDestination(for: Movie.self) { MovieDetailView(movie: $0) }
    }
}

struct MovieGrid: View {
    let movies: [Movie]
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(movies) { movie in
                NavigationLink(value: movie) {
                    VStack(alignment: .leading, spacing: 6) {
                        AsyncImage(url: movie.posterURL) { phase in
                            if let image = phase.image { image.resizable().scaledToFill() }
                            else { RoundedRectangle(cornerRadius: 10).fill(BomTheme.panel).overlay(Image(systemName: "film").foregroundStyle(.gray)) }
                        }
                        .frame(height: 155).frame(maxWidth: .infinity).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        Text(movie.name).font(.caption.weight(.semibold)).foregroundStyle(.white).lineLimit(2)
                        Text(movie.year.map(String.init) ?? "Đang cập nhật").font(.caption2).foregroundStyle(.secondary)
                    }
                }.buttonStyle(.plain)
            }
        }.padding(.horizontal)
    }
}

struct SearchView: View {
    @State private var keyword = ""
    @State private var results: [Movie] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Tên phim bạn muốn tìm…", text: $keyword)
                        .submitLabel(.search)
                        .onSubmit { Task { await search() } }
                    if !keyword.isEmpty {
                        Button { keyword = ""; results = [] } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    }
                }
                .padding(13).background(BomTheme.panel, in: RoundedRectangle(cornerRadius: 14))
                .padding()
                if isLoading { ProgressView().padding() }
                else if let errorMessage { Text(errorMessage).foregroundStyle(.secondary).padding() }
                else if results.isEmpty {
                    EmptyStateView(title: "Tìm phim", symbol: "magnifyingglass", message: "Nhập tên phim rồi nhấn Tìm trên bàn phím.")
                } else {
                    ScrollView { MovieGrid(movies: results) }
                }
                Spacer(minLength: 0)
            }
            .background(BomTheme.background)
            .navigationTitle("Tìm kiếm")
            .navigationDestination(for: Movie.self) { MovieDetailView(movie: $0) }
        }
    }

    private func search() async {
        guard !keyword.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do { results = try await PhimAPI.shared.search(keyword: keyword); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }
}

struct MovieDetailView: View {
    let movie: Movie
    @EnvironmentObject private var library: MovieLibrary
    @State private var detail: MovieDetailResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedEpisode: Episode?
    @State private var playerItem: PlayerItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AsyncImage(url: movie.backdropURL) { phase in
                    if let image = phase.image { image.resizable().scaledToFill() }
                    else { BomTheme.panel }
                }
                .frame(height: 260).frame(maxWidth: .infinity).clipped()
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Text(movie.name).font(.title.bold())
                        Spacer()
                        Button { library.toggleFavorite(movie) } label: {
                            Image(systemName: library.isFavorite(movie) ? "heart.fill" : "heart")
                                .font(.title2).foregroundStyle(BomTheme.red)
                        }
                    }
                    Text(movie.originName).foregroundStyle(.secondary)
                    HStack {
                        if let year = movie.year { Text(String(year)) }
                        if let quality = movie.quality { Text(quality) }
                        if let current = movie.episodeCurrent { Text(current) }
                    }.font(.caption.bold()).foregroundStyle(.white.opacity(0.75))
                    if isLoading { ProgressView("Đang tải danh sách tập…") }
                    if let errorMessage { Text(errorMessage).foregroundStyle(.secondary) }
                    Text("Chọn tập phim").font(.title3.bold())
                    if let servers = detail?.episodes {
                        ForEach(servers) { server in
                            Text(server.serverName).font(.headline).padding(.top, 8)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76))], spacing: 10) {
                                ForEach(server.serverData) { episode in
                                    Button(episode.name) { play(episode) }
                                        .buttonStyle(.borderedProminent)
                                        .tint(BomTheme.red)
                                }
                            }
                        }
                    }
                }.padding(.horizontal)
            }
        }
        .background(BomTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDetail() }
        .fullScreenCover(item: $playerItem) { item in VideoPlayerView(url: item.url) }
    }

    private func loadDetail() async {
        do { detail = try await PhimAPI.shared.detail(slug: movie.slug); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    private func play(_ episode: Episode) {
        guard let url = episode.playableURL else { errorMessage = "Đường dẫn video không hợp lệ."; return }
        selectedEpisode = episode
        library.addToHistory(movie)
        playerItem = PlayerItem(url: url)
    }
}

struct PlayerItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct VideoPlayerView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            VideoPlayer(player: AVPlayer(url: url)).ignoresSafeArea()
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.headline).foregroundStyle(.white)
                    .padding(12).background(.ultraThinMaterial, in: Circle())
            }.padding(.top, 18).padding(.leading, 16)
        }
        .statusBarHidden()
    }
}

struct LibraryView: View {
    @EnvironmentObject private var library: MovieLibrary
    var body: some View {
        NavigationStack {
            List {
                Section("Yêu thích") {
                    if library.favorites.isEmpty { Text("Chưa có phim yêu thích").foregroundStyle(.secondary) }
                    ForEach(library.favorites) { movie in NavigationLink(movie.name) { MovieDetailView(movie: movie) } }
                }
                Section("Đã xem") {
                    if library.history.isEmpty { Text("Lịch sử xem đang trống").foregroundStyle(.secondary) }
                    ForEach(library.history) { movie in NavigationLink(movie.name) { MovieDetailView(movie: movie) } }
                }
            }
            .scrollContentBackground(.hidden)
            .background(BomTheme.background)
            .navigationTitle("Thư viện")
        }
    }
}


struct EmptyStateView: View {
    let title: String
    let symbol: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 38))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
    }
}
