import SwiftUI

struct LoginView: View {
    @StateObject private var accountManager = AccountManager()
    
    @State private var userName = ""
    @State private var showSignInForm = false
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Username", text: $userName)
            
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
        //        .task {
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
