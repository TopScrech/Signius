import SwiftUI

struct LoginView: View {
    @Environment(AuthVM.self) private var vm
    
    @State private var username = ""
    @State private var showSignInForm = false
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Username", text: $username)
                .autocorrectionDisabled()
            
            Button("Cancel") {
                vm.cancelSignIn()
            }
            
            Button("Create Account") {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    vm.registerUserCredential_WebAuthn(window, username: username)
                }
            }
            
            Button("Log in") {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    vm.getSigninResponse_Webauthn(window)
                }
            }
            
            Button("Sign out") {
                vm.signOutWebauthnUser { success in
                    print("Sign out: \(success)")
                }
            }
            
            Button("Delete user") {
                vm.deleteUserAccount { success in
                    print("Deleted user: \(success)")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userSignedIn)) { _ in
            didFinishSignIn()
        }
        .onReceive(NotificationCenter.default.publisher(for: .modalSignInSheetCanceled)) { _ in
            showSignInForm = true
        }
    }
    
    private func didFinishSignIn() {
        vm.isSignedIn = true
    }
}
