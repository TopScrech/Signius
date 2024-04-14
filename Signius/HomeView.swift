import SwiftUI
import AuthenticationServices

struct HomeView: View {
    @Environment(NavState.self) private var navState
    @Environment(AuthVM.self) private var auth
    //    @State var userIdentifierLabel: String
    //    @State var givenNameLabel: String
    //    @State var familyNameLabel: String
    //    @State var emailLabel: String
    
    var body: some View {
        VStack {
            Text(KeychainItem.currentUserIdentifier)
            
            Button("Log out") {
//                revokeAppleToken(clientID: "8FQUA2F388", clientSecret: <#T##String#>, token: <#T##String#>, completion: <#T##(Bool, Error?) -> Void#>)
                signOut()
            }
        }
    }
    
    func signOut() {
        KeychainItem.deleteUserIdentifierFromKeychain()
        
        auth.isAuthorized = false
    }
}

#Preview {
    HomeView()
}
