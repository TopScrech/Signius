import SwiftUI

struct LoginView: View {
    @Environment(AuthVM.self) private var vm
    
    @State private var username = ""
    @State private var showSignInForm = false
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Username", text: $username)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .title3()
            
            Button("Log in") {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    vm.getSigninResponse_Webauthn(window)
                }
            }
            .buttonStyle(.green)
            
            Button("Create an Account") {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    vm.registerUserCredential_WebAuthn(window, username: username)
                }
            }
            .buttonStyle(.blue)
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

#Preview {
    LoginView()
        .environment(AuthVM())
}
