import Foundation
import Combine

struct BomProfile: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var createdAt: Date
}

@MainActor
final class ProfileStore: ObservableObject {
    static let shared = ProfileStore()
    @Published private(set) var profiles: [BomProfile] = []
    @Published var activeProfileID: String = "default" {
        didSet {
            UserDefaults.standard.set(activeProfileID, forKey: "bomphim.profile.active")
            loadPreferences()
        }
    }
    @Published private(set) var preferredGenres: Set<String> = []

    private let profilesKey = "bomphim.profile.list"

    private init() {
        let loaded: [BomProfile]
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let saved = try? JSONDecoder().decode([BomProfile].self, from: data),
           !saved.isEmpty {
            loaded = saved
        } else {
            loaded = [BomProfile(
                id: "default",
                name: UserDefaults.standard.string(forKey: "bomphim.profile.name") ?? "Tôi",
                createdAt: Date()
            )]
        }
        profiles = loaded
        let requestedID = UserDefaults.standard.string(forKey: "bomphim.profile.active") ?? loaded[0].id
        activeProfileID = loaded.contains(where: { $0.id == requestedID }) ? requestedID : loaded[0].id
        if UserDefaults.standard.data(forKey: profilesKey) == nil,
           let data = try? JSONEncoder().encode(loaded) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
        loadPreferences()
    }

    var activeProfile: BomProfile? { profiles.first { $0.id == activeProfileID } }

    func togglePreferredGenre(_ genre: String) {
        if preferredGenres.contains(genre) { preferredGenres.remove(genre) }
        else { preferredGenres.insert(genre) }
        UserDefaults.standard.set(Array(preferredGenres).sorted(), forKey: preferencesKey)
    }

    private var preferencesKey: String { "bomphim.profile.preferences.\(activeProfileID)" }

    private func loadPreferences() {
        preferredGenres = Set(UserDefaults.standard.stringArray(forKey: preferencesKey) ?? [])
    }

    func addProfile(name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, profiles.count < 8 else { return }
        profiles.append(BomProfile(id: UUID().uuidString, name: cleanName, createdAt: Date()))
        persist()
        activeProfileID = profiles[profiles.count - 1].id
    }

    func renameProfile(id: String, name: String) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        profiles[index].name = cleanName
        persist()
    }

    func deleteProfile(id: String) {
        guard profiles.count > 1 else { return }
        profiles.removeAll { $0.id == id }
        if activeProfileID == id { activeProfileID = profiles[0].id }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: profilesKey)
    }
}
