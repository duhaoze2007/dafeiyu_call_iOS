import SwiftUI

@main
struct FatFishCallApp: App {
    @StateObject private var engine = CallEngine()

    var body: some Scene {
        WindowGroup {
            CallView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
        }
    }
}
