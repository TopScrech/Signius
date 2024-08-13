import AuthenticationServices
import Alamofire
import os

private let domain = "/"
private let createUserAPIEndpoint = "http://\(domain)signup"
private let signInUserAPIEndpoint = "http://\(domain)authenticate"
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
    
    func getSigninResponse_Webauthn(anchor: ASPresentationAnchor) {
        self.authenticationAnchor = anchor
        
        AF.request(signInUserAPIEndpoint, method: .get).responseData { responseData in
            switch responseData.response?.statusCode {
            case 200:
                print("Successful")
                
                if let data = responseData.data {
                    do {
                        let signinDataResponseDecoded = try JSONDecoder().decode(SignInWebAuthnResponse.self, from: data)
                        self.signinWithResponse(response: signinDataResponseDecoded)
                    } catch {
                        print("Error decoding SignInResponse")
                    }
                }
                
            case 401:
                print("401 - Unauthorized user")
                
            case .some(_):
                print("Unkown response: \(String(describing: responseData.response?.statusCode))")
                
            case .none:
                print("Response not founda")
            }
        }
    }
    
    func signinWithResponse(response: SignInWebAuthnResponse) {
        let challengeResponseString = response.challenge
        guard let challengeBase64URLDecodedData = challengeResponseString.base64URLDecodedData() else {
            print("Error decoding challengeBase64URLDecodedData")
            return
        }
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challengeBase64URLDecodedData)
        
        let authController = ASAuthorizationController(authorizationRequests: [assertionRequest])
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
            
            // This is the unique ID for the passkey
            let credentialIDObjectBase64 = credentialRegistration.credentialID.base64EncodedString()
            
            let rawIdObject = credentialRegistration.rawAttestationObject?.base64EncodedString()
            let clientDataJSONBase64 = credentialRegistration.rawClientDataJSON.base64EncodedString()
            
            guard let attestationObjectBase64 = credentialRegistration.rawAttestationObject?.base64EncodedString() else {
                logger.log("Errpr getting attestationObjectBase64")
                return
            }
            
            let responseObject: [String: Any] = [
                "clientDataJSON": clientDataJSONBase64,
                "attestationObject": attestationObjectBase64
            ]
            
            let params: [String: Any] = [
                "id": credentialRegistration,
                "rawId": rawIdObject,
                "response": responseObject,
                "type": "public-key"
            ]
            
            AF.request(registerBeginAPIEndpoint, method: .post, parameters: params, encoding: JSONEncoding.default).responseData { responseData in
                switch responseData.response?.statusCode {
                case 200:
                    print("Successfully registered user on Wenauthn. Logging in user now")
                    
                case .none:
                    print("Response not found")
                    
                case .some(_):
                    print("Unknown response: \(String(describing: responseData.response?.statusCode))")
                }
            }
            //            sendAuthenticationDataToServer(
            //                passkey: rawAttestationObject?.base64EncodedString(),
            //                credentialId: credentialID.base64EncodedString()
            //            )
            
            
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
            fatalError("Received unknown authorization type")
        }
    }
    
    // Failed
#warning("part 20 has more error handling")
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let logger = Logger()
        
        guard let authorizationError = error as? ASAuthorizationError else {
            logger.error("Unexpected authorization error: \(error.localizedDescription)")
            return
        }
        
        if authorizationError.code == .canceled {
            logger.log("Request canceled")
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
    
    func beginWebAuthnRegistration(response: BeginWebAuthnRegistrationResponse) {
        let challengeResponseString = response.challenge
        let usernameDecoded = response.user.name
        let userIdDecoded = response.user.id
        
        let userID = Data(userIdDecoded.utf8)
        
        guard let challengeBase64EncodedData = challengeResponseString.base64URLDecodedData() else {
            print("Error decoding challengeResponseString to Data")
            return
        }
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(
            challenge: challengeBase64EncodedData,
            name: usernameDecoded,
            userID: userID
        )
        
        let authController = ASAuthorizationController(authorizationRequests: [registrationRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
    }
}

extension String {
    func base64URLDecodedData() -> Data? {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let paddingLenght = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: paddingLenght)
        
        return Data(base64Encoded: base64)
    }
}

struct SignInWebAuthnResponse: Codable {
    let challenge: String
    let timeout: Int
    let rpId: String
    let allowCredentials: [PublicKeyCredentialDescriptor]?
    let userVerification: UserVerificationRequirement?
}

struct PublicKeyCredentialDescriptor: Codable {
    let type: String
    let id: Int
    let transports: [AuthenticatorTransport]
}

struct AuthenticatorTransport: Codable {
    let usb: String
    let nfc: String
    let ble: String
    let hybrid: String
    let `internal`: String
}

enum UserVerificationRequirement: String, Codable {
    case required
    case preferred
    case discouraged
}
