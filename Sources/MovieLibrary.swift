import Foundation
import Combine

@MainActor
final class MovieLibrary: ObservableObject {
    @Published private(set) var favorites: [Movie] = []
    @Published private(set) var history: [Movie] = []

    private let favoritesKey = "bomphim.favorites"
    private let historyKey = "bomphim.history"

    init() {
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
