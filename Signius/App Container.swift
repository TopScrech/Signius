import SwiftUI

struct AppContainer: View {
    @State private var vm = AuthVM()
    
    var body: some View {
        NavigationStack {
            if vm.isSignedIn {
                AccountView()
            } else {
                LoginView()
            }
        }
        .environment(vm)
    }
}
