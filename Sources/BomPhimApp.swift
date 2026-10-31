import SwiftUI

@main
struct BomPhimApp: App {
    @StateObject private var library = MovieLibrary()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(library)
                .preferredColorScheme(.dark)
        }
    }
}
