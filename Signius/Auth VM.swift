import AuthenticationServices

@Observable
final class AuthVM {
    var token = ""
    var isAuthorized = false
    var userIdentifier = ""
    
    func loginController(_ authorization: ASAuthorization) {
        switch authorization.credential {
        case let credential as ASAuthorizationAppleIDCredential:
            guard let tokenData = credential.identityToken else {
                print("tokenData error")
                return
            }
            
            guard let token = String(data: tokenData, encoding: .utf8) else {
                print("token error")
                return
            }
            
            
            
        default:
            break
        }
    }
    
    func registrationController(_ authorization: ASAuthorization) {
        switch authorization.credential {
        case let credential as ASAuthorizationAppleIDCredential:
            guard let tokenData = credential.identityToken else {
                print("tokenData error")
                return
            }
            
            guard let token = String(data: tokenData, encoding: .utf8) else {
                print("token error")
                return
            }
            
            guard let givenName = credential.fullName?.givenName else {
                print("givenName error")
                return
            }
            
            guard let familyName = credential.fullName?.familyName else {
                print("familyName error")
                return
            }
            
            guard let name = credential.fullName?.givenName else {
                print("token error")
                return
            }
            
            guard let email = credential.email else {
                print("email error")
                return
            }
            
            userIdentifier = credential.user
            
            createUser(name: "\(givenName) \(familyName)", email: email) { result in
                switch result {
                case .success(let model):
                    print(model)
                    self.saveToken(token)
                    
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
            
            //        case let passwordCredential as ASPasswordCredential:
            //            // Sign in using an existing iCloud Keychain credential.
            //            let username = passwordCredential.user
            //            let password = passwordCredential.password
            //                self.showPasswordCredentialAlert(username: username, password: password)
            
        default:
            break
        }
    }
    
    private func saveToken(_ token: String) {
        do {
            try KeychainItem(
                service: "dev.topscrech.Signius",
                account: "userIdentifier"
            )
            .saveItem(token)
            
            isAuthorized = true
        } catch {
            print("Unable to save userIdentifier to keychain")
        }
    }
}
