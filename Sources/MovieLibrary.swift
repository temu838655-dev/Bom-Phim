import Foundation
import Combine

@MainActor
final class MovieLibrary: ObservableObject {
    @Published private(set) var favorites: [Movie] = []
    @Published private(set) var history: [Movie] = []
    private(set) var profileID: String

    init(profileID: String = "default") {
        self.profileID = profileID
        favorites = load(favoritesKey)
        history = load(historyKey)
    }

    private var favoritesKey: String { "bomphim.favorites.\(profileID)" }
    private var historyKey: String { "bomphim.history.\(profileID)" }

    func switchProfile(_ id: String) {
        guard id != profileID else { return }
        profileID = id
        favorites = load(favoritesKey)
        history = load(historyKey)
    }

    func isFavorite(_ movie: Movie) -> Bool { favorites.contains { $0.id == movie.id } }

    func toggleFavorite(_ movie: Movie) {
        if isFavorite(movie) { favorites.removeAll { $0.id == movie.id } }
        else { favorites.insert(movie, at: 0) }
        save(favorites, key: favoritesKey)
    }

    func addToHistory(_ movie: Movie) {
        history.removeAll { $0.id == movie.id }
        history.insert(movie, at: 0)
        history = Array(history.prefix(50))
        save(history, key: historyKey)
    }

    private func load(_ key: String) -> [Movie] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let result = try? JSONDecoder().decode([Movie].self, from: data) else { return [] }
        return result
    }

    private func save(_ movies: [Movie], key: String) {
        guard let data = try? JSONEncoder().encode(movies) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
