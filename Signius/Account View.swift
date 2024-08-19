import SwiftUI

struct AccountView: View {
    @Environment(AuthVM.self) private var vm
    
    var body: some View {
        Text("Hello, World!")
        
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
}

#Preview {
    AccountView()
}
