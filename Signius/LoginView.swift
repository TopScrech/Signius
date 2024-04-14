import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthVM.self) private var auth
    @Environment(NavState.self) private var navState
    @Environment(\.colorScheme) private var theme
    
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Group {
                TextField("Username", text: $username)
                
                TextField("Password", text: $password)
            }
            .autocorrectionDisabled()
            .textFieldStyle(.roundedBorder)
            
            Divider()
                .padding()
            
            SignInWithAppleButton(.signUp) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let credentials):
                    auth.registrationController(credentials)
                    
                case .failure(let error):
                    print("Authorisation failed: \(error.localizedDescription)")
                }
            }
            .frame(height: 64)
            .clipShape(.rect(cornerRadius: 16))
            .signInWithAppleButtonStyle(theme == .dark ? .white : .black)
            
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let credentials):
                    auth.registrationController(credentials)
                    
                case .failure(let error):
                    print("Authorisation failed: \(error.localizedDescription)")
                }
            }
            .frame(height: 64)
            .clipShape(.rect(cornerRadius: 16))
            .signInWithAppleButtonStyle(theme == .dark ? .white : .black)
        }
        .multilineTextAlignment(.center)
        .title3()
        .padding()
    }
}

#Preview {
    LoginView()
        .environment(NavState())
        .environment(AuthVM())
}
