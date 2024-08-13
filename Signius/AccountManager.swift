import AuthenticationServices
import Alamofire
import os

private let domain = "/"
private let createUserAPIEndpoint = "http://\(domain)signup"
private let signinUserAPIEndpoint = "http://\(domain)authenticate"
private let registerBeginAPIEndpoint = "http://\(domain)makeCredential"
private let signOutAPIEndpoint = "http://\(domain)signout"
private let deleteCredentialAPIEndpoint = "http://\(domain)deleteCredential"

func createChallenge(length: Int = 32) -> Data {
    // Ensure the length is reasonable
    guard length > 0 else {
        fatalError("Challenge length must be greater than zero.")
    }
    
    // Generate random data
    var challenge = Data(count: length)
    _ = challenge.withUnsafeMutableBytes { bytes in
        // Fill the data with random bytes
        SecRandomCopyBytes(kSecRandomDefault, length, bytes.baseAddress!)
    }
    
    return challenge
}

class AccountManager: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate, ObservableObject {
    let domain = "topscrech.dev"
    
    @Published var isSignedIn = false
    @Published var showSignInForm = false
    
    var authenticationAnchor: ASPresentationAnchor?
    private var authController: ASAuthorizationController?
    
    func cancelSignIn() {
        authController?.cancel()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        authenticationAnchor!
    }
    
    func didFinishSignIn() {
        isSignedIn = true
    }
    
    func didCancelModalSheet() {
        showSignInForm = true
    }
    
    func signInWith(anchor: ASPresentationAnchor, preferImmediatelyAvailableCredentials: Bool) {
        self.authenticationAnchor = anchor
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        let challenge = createChallenge()
        
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
        let passwordCredentialProvider = ASAuthorizationPasswordProvider()
        let passwordRequest = passwordCredentialProvider.createRequest()
        
        authController = ASAuthorizationController(authorizationRequests: [assertionRequest, passwordRequest])
        authController?.delegate = self
        authController?.presentationContextProvider = self
        
        if preferImmediatelyAvailableCredentials {
            authController?.performRequests(options: .preferImmediatelyAvailableCredentials)
        } else {
            authController?.performRequests()
        }
    }
    
    func beginAutoFillAssistedPasskeySignIn(anchor: ASPresentationAnchor) {
        self.authenticationAnchor = anchor
        
        let challenge = createChallenge()
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
        
        let authController = ASAuthorizationController(authorizationRequests: [assertionRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performAutoFillAssistedRequests()
    }
    
    func signUpWith(userName: String, anchor: ASPresentationAnchor) {
        self.authenticationAnchor = anchor
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        let challenge = createChallenge()
        let userID = Data(UUID().uuidString.utf8)
        
        let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challenge, name: userName, userID: userID)
        
        let authController = ASAuthorizationController(authorizationRequests: [registrationRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
    }
    
    // Succeed
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let logger = Logger()
        
        switch authorization.credential {
        case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
            logger.log("A new passkey was registered: \(credentialRegistration)")
            
            // Extract the credential ID and other necessary information
            let credentialID = credentialRegistration.credentialID // This is the unique ID for the passkey
            let rawAttestationObject = credentialRegistration.rawAttestationObject
            let clientDataJSON = credentialRegistration.rawClientDataJSON
            
            print(clientDataJSON)
            // Prepare the data to send to the server
            //            let registrationData: [String: Any] = [
            //                "credentialID": credentialID,
            //                "attestationObject": rawAttestationObject,
            //                "clientDataJSON": clientDataJSON
            //            ]
            
            sendAuthenticationDataToServer(
                passkey: rawAttestationObject?.base64EncodedString(),
                credentialId: credentialID.base64EncodedString()
            )
            
            // Send the registration data to the server
            //            sendRegistrationDataToServer(registrationData)
            
            didFinishSignIn()
            
        case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            logger.log("A passkey was used to sign in: \(credentialAssertion)")
            
            // Extract the data needed to authenticate with the server
            let userID = credentialAssertion.userID // This is the ID of the user who owns the credential
            let rawAuthenticatorData = credentialAssertion.rawAuthenticatorData
            let signature = credentialAssertion.signature
            let clientDataJSON = credentialAssertion.rawClientDataJSON
            
            // Send authData to your server for verification
            checkRequestServer(
                credentialAssertion.credentialID.base64EncodedString(),
                signature: signature,
                clientDataJSON: clientDataJSON
            )
            
            didFinishSignIn()
            
            
        case let passwordCredential as ASPasswordCredential:
            logger.log("A password was provided: \(passwordCredential)")
            didFinishSignIn()
            
        default:
            fatalError("Received unknown authorization type.")
        }
    }
    
    // Failed
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let logger = Logger()
        
        guard let authorizationError = error as? ASAuthorizationError else {
            logger.error("Unexpected authorization error: \(error.localizedDescription)")
            return
        }
        
        if authorizationError.code == .canceled {
            logger.log("Request canceled.")
            didCancelModalSheet()
        } else {
            logger.error("Error: \((error as NSError).userInfo)")
        }
        
        controller.cancel()
    }
}

extension AccountManager {
    func registerUserCredential_WebAuthn(anchor: ASPresentationAnchor, username: String) {
        self.authenticationAnchor = anchor
        
        let params: Parameters = [
            "username": username
        ]
        
        AF.request(createUserAPIEndpoint, method: .get, parameters: params).responseData { responseData in
            switch responseData.response?.statusCode {
            case 200:
                print("Successful")
                AF.request(registerBeginAPIEndpoint, method: .get).responseData { responseData in
                    if let data = responseData.data {
                        do {
                            let registerDataResponseDecoded = try JSONDecoder().decode(BeginWebAuthnRegistrationResponse.self, from: data)
                        } catch {
                            print("Error decoding BeginWebAuthnRegistrationResponse")
                        }
                    }
                }
                
            case 409:
                print("Conflict")
                
            case .some(_):
                print("Other response")
                
            case .none:
                print("No response")
            }
        }
    }
}
