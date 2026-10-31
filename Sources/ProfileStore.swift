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
    @Published var activeProfileID: String {
        didSet {
            UserDefaults.standard.set(activeProfileID, forKey: "bomphim.profile.active")
        }
    }

    private let profilesKey = "bomphim.profile.list"

    private init() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let saved = try? JSONDecoder().decode([BomProfile].self, from: data),
           !saved.isEmpty {
            profiles = saved
        } else {
            let initial = BomProfile(id: "default", name: UserDefaults.standard.string(forKey: "bomphim.profile.name") ?? "Tôi", createdAt: Date())
            profiles = [initial]
            persist()
        }
        let savedID = UserDefaults.standard.string(forKey: "bomphim.profile.active") ?? profiles[0].id
        activeProfileID = profiles.contains(where: { $0.id == savedID }) ? savedID : profiles[0].id
    }

    var activeProfile: BomProfile? { profiles.first { $0.id == activeProfileID } }

    func addProfile(name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, profiles.count < 8 else { return }
        let profile = BomProfile(id: UUID().uuidString, name: cleanName, createdAt: Date())
        profiles.append(profile)
        persist()
        activeProfileID = profile.id
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
