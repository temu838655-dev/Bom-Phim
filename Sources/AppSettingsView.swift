import SwiftUI
import Security

struct AppSettingsView: View {
    @AppStorage("bomphim.language") private var language = "Tiếng Việt"
    @AppStorage("bomphim.theme") private var theme = "Đỏ điện ảnh"
    @AppStorage("bomphim.profile.enabled") private var profileEnabled = false
    @AppStorage("bomphim.profile.name") private var profileName = "Tôi"
    @State private var pin = ""
    @State private var pinConfirmation = ""
    @State private var hasPIN = PINStore.hasPIN
    @State private var message: String?\n    @StateObject private var profileStore = ProfileStore.shared\n    @State private var newProfileName = ""

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
                        TextField("Tên hồ sơ", text: $profileName)
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
                                PINStore.delete()
                                hasPIN = false
                                pin = ""
                                pinConfirmation = ""
                                message = "Đã xóa mã PIN trên thiết bị."
                            }
                        }
                        Text("Mã PIN được lưu trong Keychain của iPhone và dùng để mở khóa hồ sơ.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Tắt hồ sơ để vào thẳng trang chủ, không cần chọn hồ sơ.")
                            .font(.caption).foregroundStyle(.secondary)
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
        if PINStore.save(pin) {
            hasPIN = true
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
    private static let account = "profile-pin"
    static var hasPIN: Bool {
        var query = baseQuery
        query[kSecReturnData as String] = false
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }
    static func verify(_ pin: String) -> Bool {\n        var query = baseQuery\n        query[kSecReturnData as String] = true\n        query[kSecMatchLimit as String] = kSecMatchLimitOne\n        var result: CFTypeRef?\n        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,\n              let data = result as? Data, let saved = String(data: data, encoding: .utf8) else { return false }\n        return saved == pin\n    }\n    static func save(_ pin: String) -> Bool {
        delete()
        var query = baseQuery
        query[kSecValueData as String] = Data(pin.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
    static func delete() { SecItemDelete(baseQuery as CFDictionary) }
    private static var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }
}
