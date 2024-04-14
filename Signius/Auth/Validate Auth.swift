import AuthenticationServices

func validateAuth(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
    completion: @escaping (Bool) -> Void
) {
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    
    appleIDProvider.getCredentialState(forUserID: KeychainItem.currentUserIdentifier) { credentialState, error in
        switch credentialState {
        case .authorized:
            completion(true)
            
        case .revoked, .notFound:
            completion(false)
            
        default:
            completion(false)
        }
        
        if let error {
            print("Error occurred while getting credential state: \(error.localizedDescription)")
            completion(false)
        }
    }
}
