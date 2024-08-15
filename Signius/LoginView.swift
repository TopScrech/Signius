import SwiftUI

struct LoginView: View {
    @StateObject private var accountManager = AccountManager()
    
    @State private var userName = "2efew2"
    @State private var showSignInForm = false
    
    var body: some View {
        VStack {
            Button("Cancel") {
                accountManager.cancelSignIn()
            }
            
//            if showSignInForm {
//                signInForm
//            } else {
                Button("Create Account") {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        accountManager.registerUserCredential_WebAuthn(
                            anchor: window,
                            username: userName
                        )
                    }
                }
//            }
            
            Button("Log in") {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    accountManager.getSigninResponse_Webauthn(anchor: window)
                }
            }
        }
        //        .onAppear {
        //            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        //               let window = windowScene.windows.first {
        //                accountManager.signInWith(
        //                    anchor: window,
        //                    preferImmediatelyAvailableCredentials: true
        //                )
        //            }
        //        }
        .onReceive(NotificationCenter.default.publisher(for: .UserSignedIn)) { _ in
            didFinishSignIn()
        }
        .onReceive(NotificationCenter.default.publisher(for: .ModalSignInSheetCanceled)) { _ in
            showSignInForm = true
        }
    }
    
//    private var signInForm: some View {
//        VStack {
//            TextField("User Name", text: $userName)
//                .textFieldStyle(.roundedBorder)
//            
//            Button("Sign In") {
//                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                   let window = windowScene.windows.first {
//                    accountManager.beginAutoFillAssistedPasskeySignIn(anchor: window)
//                }
//            }
//        }
//        .padding()
//    }
    
    func didFinishSignIn() {
        accountManager.isSignedIn = true
    }
}
