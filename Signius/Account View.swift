import SwiftUI

struct AccountView: View {
    @Environment(AuthVM.self) private var vm
    
    var body: some View {
        Button("Sign out") {
            vm.signOutWebauthnUser { success in
                print("Sign out: \(success)")
            }
        }
        .buttonStyle(.red)
        
        Button("Delete user") {
            vm.deleteUserAccount { success in
                print("Deleted user: \(success)")
            }
        }
        .buttonStyle(.black)
    }
}

#Preview {
    AccountView()
        .environment(AuthVM())
}
