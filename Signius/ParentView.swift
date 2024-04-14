import SwiftUI

struct ParentView: View {
    private var auth = AuthVM()
    
    var body: some View {
        VStack {
            if auth.isAuthorized {
                HomeView()
            } else {
                LoginView()
            }
        }
        .environment(auth)
        .task {
            validateAuth(UIApplication.shared, didFinishLaunchingWithOptions: nil) { isAuthorized in
                auth.isAuthorized = isAuthorized
            }
        }
    }
}
