import SwiftUI

@main
struct SigniusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    let accountManager = AccountManager()
}

struct UserHomeView: View {
    @EnvironmentObject var accountManager: AccountManager
    
    var body: some View {
        VStack {
            Text("Welcome!")
            
            Button("Sign Out") {
                accountManager.isSignedIn = false
            }
        }
    }
}

extension Notification.Name {
    static let UserSignedIn = Notification.Name("UserSignedInNotification")
    static let ModalSignInSheetCanceled = Notification.Name("ModalSignInSheetCanceledNotification")
}
