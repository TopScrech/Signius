import SwiftUI

struct AppContainer: View {
    @Bindable private var navState = NavState()
    
    var body: some View {
        NavigationStack(path: $navState.path) {
            ParentView()
                .withNavDestinations()
        }
        .environment(navState)
    }
}

#Preview {
    AppContainer()
}
