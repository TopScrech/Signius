import SwiftUI

struct AppContainer: View {
    @State private var vm = AuthVM()
    
    var body: some View {
        NavigationStack {
            LoginView()
                .environment(vm)
        }
    }
}
