import SwiftUI
import Security

struct AppSettingsView: View {
    @AppStorage("bomphim.language") private var language = "Tiếng Việt"
    @AppStorage("bomphim.theme") private var theme = "Đỏ điện ảnh"
    @AppStorage("bomphim.profile.enabled") private var profileEnabled = false
    @AppStorage("bomphim.profile.name") private var profileName = "Tôi"
    @State private var pin = ""
    @State private var pinConfirmation = ""
    @State private var message: String?
    @StateObject private var profileStore = ProfileStore.shared
    @State private var newProfileName = ""

    private var hasPIN: Bool { PINStore.hasPIN(for: profileStore.activeProfileID) }

    private let languages = ["Tiếng Việt", "English", "中文", "日本語", "한국어", "ไทย", "Français", "Español"]
    private let themes = ["Đỏ điện ảnh", "Xanh đại dương", "Tím neon", "Xanh ngọc", "Sáng tối giản"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Ngôn ngữ") {
                    Picker("Ngôn ngữ ứng dụng", selection: $language) {
                        ForEach(languages, id: \.self) { Text($0).tag($0) }
                    }
                    Text("Lựa chọn được lưu trên thiết bị. Bản dịch toàn bộ giao diện sẽ được bổ sung đồng bộ ở bước bản địa hóa.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Hồ sơ người dùng") {
                    Toggle("Sử dụng hồ sơ", isOn: $profileEnabled)
                    if profileEnabled {
                        TextField("Tên hồ sơ", text: Binding(\n                            get: { profileStore.activeProfile?.name ?? profileName },\n                            set: { profileStore.renameProfile(id: profileStore.activeProfileID, name: $0) }\n                        ))
                        HStack {
                            Label("Mã PIN hồ sơ", systemImage: "lock.fill")
                            Spacer()
                            Text(hasPIN ? "Đã thiết lập" : "Chưa thiết lập")
                                .foregroundStyle(hasPIN ? .green : .secondary)
                        }
                        SecureField("Nhập mã PIN (4–8 số)", text: $pin).keyboardType(.numberPad)
                        SecureField("Nhập lại mã PIN", text: $pinConfirmation).keyboardType(.numberPad)
                        Button(hasPIN ? "Đổi mã PIN" : "Lưu mã PIN") { savePIN() }
                            .disabled(pin.count < 4 || pin.count > 8 || pin != pinConfirmation || !pin.allSatisfy(\.isNumber))
                        if hasPIN {
                            Button("Xóa mã PIN", role: .destructive) {
                                PINStore.delete(for: profileStore.activeProfileID)
                                pin = ""
                                pinConfirmation = ""
                                message = "Đã xóa mã PIN trên thiết bị."
                            }
                        }
                        Text("Mã PIN được lưu trong Keychain của iPhone và dùng để mở khóa hồ sơ.")
                            .font(.caption).foregroundStyle(.secondary)
                        HStack {
                            TextField("Tên hồ sơ mới", text: $newProfileName)
                            Button("Thêm") {
                                profileStore.addProfile(name: newProfileName)
                                newProfileName = ""
                            }
                            .disabled(newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || profileStore.profiles.count >= 8)
                        }
                        ForEach(profileStore.profiles) { profile in
                            HStack {
                                Button {
                                    profileStore.activeProfileID = profile.id
                                } label: {
                                    HStack {
                                        Text(profile.name)
                                        Spacer()
                                        if profile.id == profileStore.activeProfileID {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                if profileStore.profiles.count > 1 {
                                    Button(role: .destructive) {
                                        profileStore.deleteProfile(id: profile.id)
                                    } label: { Image(systemName: "trash") }
                                }
                            }
                        }
                        Text("Tối đa 8 hồ sơ. Mỗi hồ sơ có lịch sử xem và danh sách yêu thích riêng.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Tắt hồ sơ để vào thẳng trang chủ, không cần chọn hồ sơ.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                if profileEnabled {
                    Section("Sở thích phim của hồ sơ") {
                        Text("Chọn thể loại bạn thường xem. Sở thích được lưu riêng cho từng hồ sơ.")
                            .font(.caption).foregroundStyle(.secondary)
                        ForEach(["Hành động", "Hài", "Tình cảm", "Kinh dị", "Viễn tưởng", "Hoạt hình", "Tâm lý", "Phiêu lưu", "Tài liệu", "Gia đình"], id: \.self) { genre in
                            Button {
                                profileStore.togglePreferredGenre(genre)
                            } label: {
                                HStack {
                                    Text(genre)
                                    Spacer()
                                    if profileStore.preferredGenres.contains(genre) {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                                    } else {
                                        Image(systemName: "circle").foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section("Giao diện") {
                    Picker("Chủ đề", selection: $theme) {
                        ForEach(themes, id: \.self) { Text($0).tag($0) }
                    }
                    ForEach(themes, id: \.self) { item in
                        HStack {
                            Circle().fill(color(for: item)).frame(width: 18, height: 18)
                            Text(item)
                            Spacer()
                            if theme == item { Image(systemName: "checkmark").foregroundStyle(.tint) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { theme = item }
                    }
                    Text("Chủ đề được lưu. Việc đồng bộ màu sắc cho tất cả màn hình sẽ tiếp tục được hoàn thiện.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let message { Section { Text(message).font(.footnote) } }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Cài đặt")
        }
    }

    private func savePIN() {
        guard pin.count >= 4, pin.count <= 8, pin.allSatisfy(\.isNumber), pin == pinConfirmation else {
            message = "Mã PIN phải gồm 4–8 chữ số và hai lần nhập phải trùng nhau."
            return
        }
        if PINStore.save(pin, for: profileStore.activeProfileID) {
            pin = ""
            pinConfirmation = ""
            message = "Đã lưu mã PIN hồ sơ an toàn trên thiết bị."
        } else {
            message = "Không thể lưu mã PIN. Vui lòng thử lại."
        }
    }

    private func color(for item: String) -> Color {
        switch item {
        case "Xanh đại dương": return .blue
        case "Tím neon": return .purple
        case "Xanh ngọc": return .mint
        case "Sáng tối giản": return .gray
        default: return .red
        }
    }
}

enum PINStore {
    private static let service = "com.bomphim.profile"

    static func hasPIN(for profileID: String) -> Bool {
        var query = baseQuery(for: profileID)
        query[kSecReturnData as String] = false
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    static func verify(_ pin: String, for profileID: String) -> Bool {
        var query = baseQuery(for: profileID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let saved = String(data: data, encoding: .utf8) else { return false }
        return saved == pin
    }

    static func save(_ pin: String, for profileID: String) -> Bool {
        delete(for: profileID)
        var query = baseQuery(for: profileID)
        query[kSecValueData as String] = Data(pin.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func delete(for profileID: String) {
        SecItemDelete(baseQuery(for: profileID) as CFDictionary)
    }

    private static func baseQuery(for profileID: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: "profile-pin-\(profileID)"]
    }
}
