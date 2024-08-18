import SwiftUI

@main
struct SigniusApp: App {
    @State private var vm = AccountManager()
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environment(vm)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    let accountManager = AccountManager()
}

extension Notification.Name {
    static let userSignedIn = Notification.Name("UserSignedInNotification")
    static let modalSignInSheetCanceled = Notification.Name("ModalSignInSheetCanceledNotification")
}
