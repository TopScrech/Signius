import SwiftUI

extension View {
    func withNavDestinations() -> some View {
        self.navigationDestination(for: NavDestinations.self) { destination in
            switch destination {
            case .home:
                HomeView()
            }
        }
    }
}
