import SwiftUI

@main
struct BomPhimApp: App {
    @StateObject private var library = MovieLibrary()
    @AppStorage("bomphim.theme") private var theme = "Đỏ điện ảnh"

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(library)
                .preferredColorScheme(theme == "Sáng tối giản" ? .light : .dark)
        }
    }
}
