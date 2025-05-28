import SwiftUI

struct AccountView: View {
    @Environment(AuthVM.self) private var vm
    
    var body: some View {
        Button {
            vm.signOutWebauthnUser()
        } label: {
            Text("Sign out")
                .buttonStyle(.red)
        }
        
        Button {
            vm.deleteUserAccount()
        } label: {
            Text("Delete user")
                .buttonStyle(.black)
        }
    }
}

#Preview {
    AccountView()
        .environment(AuthVM())
}
