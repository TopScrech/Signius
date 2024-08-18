import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var accountManager: AccountManager
    
    @State private var username = ""
    @State private var showSignInForm = false
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Username", text: $username)
            
            Button("Cancel") {
                accountManager.cancelSignIn()
            }
            
            Button("Create Account") {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    accountManager.registerUserCredential_WebAuthn(
                        anchor: window,
                        username: username
                    )
                }
            }
            
            Button("Log in") {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    accountManager.getSigninResponse_Webauthn(anchor: window)
                }
            }
            
            Button("Sign out") {
                accountManager.signOutWebauthnUser { isSuccess in
                    print("Sign out: \(isSuccess)")
                }
            }
            
            Button("Delete user") {
                accountManager.deleteUserAccount { isDeleted in
                    print("Deleted user: \(isDeleted)")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .UserSignedIn)) { _ in
            didFinishSignIn()
        }
        .onReceive(NotificationCenter.default.publisher(for: .ModalSignInSheetCanceled)) { _ in
            showSignInForm = true
        }
    }
    
    func didFinishSignIn() {
        accountManager.isSignedIn = true
    }
}
