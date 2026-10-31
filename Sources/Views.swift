import SwiftUI
import AVKit

private enum BomTheme {
    static var background: Color { (UserDefaults.standard.string(forKey: "bomphim.theme") ?? "Đỏ điện ảnh") == "Sáng tối giản" ? Color(red: 0.96, green: 0.96, blue: 0.98) : Color(red: 0.035, green: 0.035, blue: 0.045) }
    static let panel = Color(red: 0.105, green: 0.105, blue: 0.12)
    static var red: Color {
        switch UserDefaults.standard.string(forKey: "bomphim.theme") ?? "Đỏ điện ảnh" {
        case "Xanh đại dương": return .blue
        case "Tím neon": return .purple
        case "Xanh ngọc": return .mint
        case "Sáng tối giản": return .gray
        default: return Color(red: 0.9, green: 0.04, blue: 0.09)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var library: MovieLibrary
    @StateObject private var profileStore = ProfileStore.shared
    @AppStorage("bomphim.profile.enabled") private var profileEnabled = false
    @AppStorage("bomphim.theme") private var theme = "Đỏ điện ảnh"
    @State private var isUnlocked = false
    @State private var pendingProfileID: String?
    @State private var pin = ""
    @State private var pinError: String?

    var body: some View {
        Group {
            if profileEnabled && !isUnlocked {
                profileAccess
            } else {
                tabs
            }
        }
        .id(theme)
        .environment(\.locale, Locale(identifier: AppLanguage.identifier))
        .preferredColorScheme(theme == "Sáng tối giản" ? .light : .dark)
        .onAppear {
            library.switchProfile(profileStore.activeProfileID)
            if !profileEnabled { isUnlocked = true }
        }
        .onChange(of: profileStore.activeProfileID) { id in
            library.switchProfile(id)
        }
        .onChange(of: profileEnabled) { enabled in
            isUnlocked = !enabled
            pin = ""
            pinError = nil
        }
    }

    private var tabs: some View {
        TabView {
            HomeView()
                .tabItem { Label(T("Trang chủ"), systemImage: "house.fill") }
            SearchView()
                .tabItem { Label(T("Tìm kiếm"), systemImage: "magnifyingglass") }
            LibraryView()
                .tabItem { Label(T("Thư viện"), systemImage: "bookmark.fill") }
            AppSettingsView()
                .tabItem { Label(T("Cài đặt"), systemImage: "gearshape.fill") }
        }
        .tint(BomTheme.red)
        .background(BomTheme.background)
    }

    private var profileAccess: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 42)).foregroundStyle(BomTheme.red)
                Text(T("Chọn hồ sơ")).font(.largeTitle.bold())
                Text(T("Chọn hồ sơ để xem thư viện và lịch sử riêng."))
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
                ForEach(profileStore.profiles) { profile in
                    Button {
                        pendingProfileID = profile.id
                        pin = ""
                        pinError = nil
                        if !PINStore.hasPIN(for: profile.id) { unlockSelectedProfile() }
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.fill").font(.title2)
                            Text(profile.name).font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding().background(BomTheme.panel, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                if pendingProfileID != nil && PINStore.hasPIN(for: pendingProfileID ?? "") {
                    SecureField(T("Nhập mã PIN hồ sơ"), text: $pin)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.top, 8)
                    Button(T("Mở hồ sơ")) {
                        if let selectedID = pendingProfileID, PINStore.verify(pin, for: selectedID) { unlockSelectedProfile() }
                        else { pinError = "Mã PIN không chính xác." }
                    }
                    .buttonStyle(.borderedProminent).tint(BomTheme.red)
                    if let pinError { Text(pinError).foregroundStyle(.red).font(.footnote) }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BomTheme.background)
        }
    }

    private func unlockSelectedProfile() {
        guard let id = pendingProfileID else { return }
        profileStore.activeProfileID = id
        library.switchProfile(id)
        isUnlocked = true
        pendingProfileID = nil
        pin = ""
    }
}

struct HomeView: View {
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var featuredIndex = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if !movies.isEmpty {
                        FeaturedMovieView(movie: movies[featuredIndex % movies.count])
                    }
                    HStack {
                        Text(T("Mới cập nhật")).font(.title2.bold())
                        Spacer()
                        Text(T("PHIMAPI")).font(.caption2.bold()).foregroundStyle(.secondary)
                    }.padding(.horizontal)
                    if isLoading && movies.isEmpty {
                        ProgressView("Đang tải phim…").frame(maxWidth: .infinity).padding(40)
                    } else if let errorMessage, movies.isEmpty {
                        EmptyStateView(title: "Chưa tải được phim", symbol: "wifi.exclamationmark", message: errorMessage)
                            .padding()
                        Button(T("Thử lại")) { Task { await loadMovies() } }
                            .buttonStyle(.borderedProminent).tint(BomTheme.red)
                    } else {
                        MovieGrid(movies: movies)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(BomTheme.background)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                if movies.isEmpty { await loadMovies() }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(6))
                    guard !Task.isCancelled, !movies.isEmpty else { continue }
                    withAnimation(.easeInOut(duration: 0.55)) {
                        featuredIndex = (featuredIndex + 1) % movies.count
                    }
                }
            }
            .refreshable { await loadMovies(); featuredIndex = 0 }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(T("BOM")).font(.system(size: 29, weight: .black, design: .rounded)).foregroundStyle(BomTheme.red)
                Text(T("PHIM")).font(.system(size: 12, weight: .heavy, design: .rounded)).tracking(5)
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
            featuredIndex = 0
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
                    Text(T("ĐỀ XUẤT HÔM NAY")).font(.caption.bold()).tracking(2).foregroundStyle(BomTheme.red)
                    Text(movie.name).font(.largeTitle.bold()).lineLimit(2)
                    HStack(spacing: 10) {
                        Label(movie.year.map(String.init) ?? "Mới", systemImage: "calendar")
                        if let quality = movie.quality { Text(quality) }
                    }.font(.caption).foregroundStyle(.white.opacity(0.75))
                    Label(T("Xem chi tiết"), systemImage: "play.fill").font(.subheadline.bold())
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
                        Text(movie.name).font(.caption.weight(.semibold)).foregroundStyle(.primary).lineLimit(2)
                        Text(T(movie.year.map(String.init) ?? "Đang cập nhật")).font(.caption2).foregroundStyle(.secondary)
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
                    TextField(T("Tên phim bạn muốn tìm…"), text: $keyword)
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
            .navigationTitle(T("Tìm kiếm"))
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
                    Text(T("Chọn tập phim")).font(.title3.bold())
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
    @State private var player = AVPlayer()
    @State private var isLandscapeRequested = false
    @State private var subtitleOptions: [AVMediaSelectionOption] = []
    @State private var subtitleGroup: AVMediaSelectionGroup?
    @State private var selectedSubtitleName: String?
    @State private var subtitleCues: [SubtitleCue] = []
    @State private var currentSubtitle = ""
    @State private var subtitleFontSize: Double = UserDefaults.standard.object(forKey: "bomphim.subtitle.size") as? Double ?? 22
    @State private var subtitleColorName = UserDefaults.standard.string(forKey: "bomphim.subtitle.color") ?? "Trắng"
    @State private var showingSubtitleImporter = false
    @State private var subtitleImportError: String?
    @State private var timeObserver: Any?
    @AppStorage("bomphim.audio.mode") private var audioMode = "Tự động"

    private var subtitleColor: Color {
        switch subtitleColorName {
        case "Vàng": return .yellow
        case "Xanh": return .cyan
        case "Hồng": return .pink
        default: return .white
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            VideoPlayer(player: player).ignoresSafeArea()
            if !currentSubtitle.isEmpty {
                Text(currentSubtitle)
                    .font(.system(size: subtitleFontSize, weight: .semibold))
                    .foregroundStyle(subtitleColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 58)
                    .allowsHitTesting(false)
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.headline).foregroundStyle(.white)
                            .padding(12).background(.ultraThinMaterial, in: Circle())
                    }
                    Menu {
                        Button(T("Tắt phụ đề")) {
                            if let group = subtitleGroup { player.currentItem?.select(nil, in: group) }
                            subtitleCues = []
                            currentSubtitle = ""
                            selectedSubtitleName = nil
                        }
                        if !subtitleOptions.isEmpty {
                            Section(T("Phụ đề nhúng")) {
                                ForEach(Array(subtitleOptions.enumerated()), id: \.offset) { _, option in
                                    Button(option.displayName) {
                                        if let group = subtitleGroup {
                                            player.currentItem?.select(option, in: group)
                                            selectedSubtitleName = option.displayName
                                            subtitleCues = []
                                            currentSubtitle = ""
                                        }
                                    }
                                }
                            }
                        }
                        Section(T("Phụ đề ngoài")) {
                            Button(T("Mở tệp .SRT / .VTT")) { showingSubtitleImporter = true }
                            if !subtitleCues.isEmpty {
                                Button(T("Tăng cỡ chữ")) { setSubtitleSize(min(40, subtitleFontSize + 2)) }
                                Button(T("Giảm cỡ chữ")) { setSubtitleSize(max(14, subtitleFontSize - 2)) }
                                Menu(T("Màu chữ")) {
                                    ForEach(["Trắng", "Vàng", "Xanh", "Hồng"], id: \.self) { color in
                                        Button(color) { setSubtitleColor(color) }
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("CC", systemImage: "captions.bubble")
                            .font(.headline).foregroundStyle(.white)
                            .padding(12).background(.ultraThinMaterial, in: Capsule())
                    }
                    .accessibilityLabel(T("Phụ đề"))
                    Menu {
                        Button {
                            audioMode = "Tự động"
                        } label: {
                            Label(T("Tự động (khuyến nghị)"), systemImage: audioMode == "Tự động" ? "checkmark" : "waveform")
                        }
                        Button {
                            audioMode = "Spatial Audio"
                        } label: {
                            Label(T("Spatial Audio"), systemImage: audioMode == "Spatial Audio" ? "checkmark" : "headphones")
                        }
                        Button {
                            audioMode = "Tiêu chuẩn"
                        } label: {
                            Label(T("Âm thanh tiêu chuẩn"), systemImage: audioMode == "Tiêu chuẩn" ? "checkmark" : "speaker.wave.2")
                        }
                    } label: {
                        Image(systemName: "waveform").font(.headline).foregroundStyle(.white)
                            .padding(12).background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel(T("Tùy chọn âm thanh"))
                    Spacer()
                }
                if let subtitleImportError {
                    Text(subtitleImportError)
                        .font(.caption).foregroundStyle(.white)
                        .padding(8).background(.black.opacity(0.7), in: Capsule())
                }
            }
            .padding(.top, 18)
            .padding(.leading, 16)
        }
        .statusBarHidden()
        .fileImporter(isPresented: $showingSubtitleImporter, allowedContentTypes: [.plainText], allowsMultipleSelection: false) { result in
            importSubtitle(result)
        }
        .onAppear {
            configureAudioSession()
            let item = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: item)
            loadSubtitleOptions(from: item)
            installSubtitleTimeObserver()
            requestOrientation(.landscape)
            isLandscapeRequested = true
            player.play()
        }
        .onDisappear {
            player.pause()
            if let timeObserver {
                player.removeTimeObserver(timeObserver)
                self.timeObserver = nil
            }
            currentSubtitle = ""
            subtitleCues = []
            player.replaceCurrentItem(with: nil)
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            if isLandscapeRequested {
                requestOrientation(.portrait)
                isLandscapeRequested = false
            }
        }
    }

    private func configureAudioSession() {
        // AVPlayer uses the system audio pipeline. iOS can select Atmos / spatial
        // output when the media stream and connected audio device support it.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            // Playback can still proceed using the system's current audio session.
        }
    }

    private func importSubtitle(_ result: Result<[URL], Error>) {
        do {
            guard let fileURL = try result.get().first else { return }
            let granted = fileURL.startAccessingSecurityScopedResource()
            defer { if granted { fileURL.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: fileURL)
            guard let content = decodeSubtitleData(data) else {
                subtitleImportError = T("Không đọc được mã hóa tệp phụ đề. Hãy lưu tệp dưới dạng UTF-8.")
                return
            }
            let parsed = SubtitleParser.parse(content)
            guard !parsed.isEmpty else {
                subtitleImportError = T("Không tìm thấy phụ đề hợp lệ trong tệp.")
                return
            }
            subtitleCues = parsed
            currentSubtitle = ""
            selectedSubtitleName = fileURL.lastPathComponent
            if let group = subtitleGroup { player.currentItem?.select(nil, in: group) }
            subtitleImportError = nil
        } catch {
            subtitleImportError = error.localizedDescription
        }
    }

    private func decodeSubtitleData(_ data: Data) -> String? {
        // Subtitle files may be saved in UTF-8, UTF-16, or legacy Windows encoding.
        let encodings: [String.Encoding] = [.utf8, .utf16, .utf16LittleEndian, .utf16BigEndian, .windowsCP1252]
        for encoding in encodings {
            if let text = String(data: data, encoding: encoding), !text.isEmpty {
                return text
            }
        }
        return nil
    }

    private func installSubtitleTimeObserver() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let seconds = time.seconds
            guard seconds.isFinite else { return }
            // If cues overlap, prefer the most recently started cue.
            currentSubtitle = subtitleCues
                .filter { seconds >= $0.start && seconds < $0.end }
                .max(by: { $0.start < $1.start })?.text ?? ""
        }
    }

    private func setSubtitleSize(_ size: Double) {
        subtitleFontSize = size
        UserDefaults.standard.set(size, forKey: "bomphim.subtitle.size")
    }

    private func setSubtitleColor(_ color: String) {
        subtitleColorName = color
        UserDefaults.standard.set(color, forKey: "bomphim.subtitle.color")
    }

    private func loadSubtitleOptions(from item: AVPlayerItem) {
        if let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            subtitleGroup = group
            subtitleOptions = group.options
            if let current = item.currentMediaSelection.selectedMediaOption(in: group) {
                selectedSubtitleName = current.displayName
            }
        } else {
            subtitleGroup = nil
            subtitleOptions = []
        }
    }

    private func requestOrientation(_ orientation: UIInterfaceOrientationMask) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        if #available(iOS 16.0, *) {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIDevice.current.setValue(
                orientation == .landscape ? UIInterfaceOrientation.landscapeRight.rawValue : UIInterfaceOrientation.portrait.rawValue,
                forKey: "orientation"
            )
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject private var library: MovieLibrary
    var body: some View {
        NavigationStack {
            List {
                Section(T("Yêu thích")) {
                    if library.favorites.isEmpty { Text(T("Chưa có phim yêu thích")).foregroundStyle(.secondary) }
                    ForEach(library.favorites) { movie in NavigationLink(movie.name) { MovieDetailView(movie: movie) } }
                }
                Section(T("Đã xem")) {
                    if library.history.isEmpty { Text(T("Lịch sử xem đang trống")).foregroundStyle(.secondary) }
                    ForEach(library.history) { movie in NavigationLink(movie.name) { MovieDetailView(movie: movie) } }
                }
            }
            .scrollContentBackground(.hidden)
            .background(BomTheme.background)
            .navigationTitle(T("Thư viện"))
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
            Text(T(title)).font(.headline)
            Text(T(message)).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
    }
}
