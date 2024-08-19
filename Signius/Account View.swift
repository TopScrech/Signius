import SwiftUI

struct AccountView: View {
    @Environment(AuthVM.self) private var vm
    
    var body: some View {
        Button("Sign out") {
            vm.signOutWebauthnUser()
        }
        .buttonStyle(.red)
        
        Button("Delete user") {
            vm.deleteUserAccount()
        }
        .buttonStyle(.black)
    }
}

#Preview {
    AccountView()
        .environment(AuthVM())
}
