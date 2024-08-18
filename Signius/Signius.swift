import SwiftUI

@main
struct SigniusApp: App {
    @StateObject private var vm = AccountManager()
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(vm)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    let accountManager = AccountManager()
}

extension Notification.Name {
    static let UserSignedIn = Notification.Name("UserSignedInNotification")
    static let ModalSignInSheetCanceled = Notification.Name("ModalSignInSheetCanceledNotification")
}
