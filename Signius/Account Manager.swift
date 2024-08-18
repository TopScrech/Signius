import AuthenticationServices
import Alamofire
import os

private let domain = "bisquit-id.topscrech.dev/"
private let createUserAPIEndpoint = "https://\(domain)signup"
private let signInUserAPIEndpoint = "https://\(domain)authenticate"
private let registerBeginAPIEndpoint = "https://\(domain)makeCredential"
private let signOutAPIEndpoint = "https://\(domain)signout"
private let deleteCredentialAPIEndpoint = "https://\(domain)deleteCredential"

@Observable
final class AccountManager: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    var isSignedIn = false
    var showSignInForm = false
    
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
                print("Response not found \(#function)")
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
        authController.performRequests(options: .preferImmediatelyAvailableCredentials)
    }
    
    // Succeed
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let logger = Logger()
        
        switch authorization.credential {
        case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
            logger.log("A new passkey was registered: \(credentialRegistration)")
            
            // This is the unique ID for the passkey
            let credentialIDObjectBase64 = credentialRegistration.credentialID.base64EncodedString()
            
            let rawIdObject = credentialRegistration.credentialID.base64EncodedString()
            let clientDataJsonBase64 = credentialRegistration.rawClientDataJSON.base64EncodedString()
            
            guard let attestationObjectBase64 = credentialRegistration.rawAttestationObject?.base64EncodedString() else {
                logger.log("Errpr getting attestationObjectBase64")
                return
            }
            
            let responseObject: [String: Any] = [
                "clientDataJSON": clientDataJsonBase64,
                "attestationObject": attestationObjectBase64
            ]
            
            let params: [String: Any] = [
                "id": credentialIDObjectBase64,
                "rawId": rawIdObject,
                "response": responseObject,
                "type": "public-key"
            ]
            
            print(params)
            
            AF.request(registerBeginAPIEndpoint, method: .post, parameters: params, encoding: JSONEncoding.default).responseData { responseData in
                switch responseData.response?.statusCode {
                case 200:
                    print("Successfully registered user on Wenauthn. Logging in user now")
                    
                case .none:
                    print("Response not found \(#function)")
                    
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
            logger.log("A passkey was used to sign in")
            
            let credentialIDObjectBase64 = credentialAssertion.credentialID.base64EncodedString()
            let rawIDObject = credentialAssertion.credentialID.base64EncodedString()
            let clientDataJSONBase64 = credentialAssertion.rawClientDataJSON.base64EncodedString()
            let authenticatorData = credentialAssertion.rawAuthenticatorData.base64EncodedString()
            
            let signature = credentialAssertion.signature.base64EncodedString()
            let userHandle = credentialAssertion.userID.base64EncodedString()
            
            let responseObject: [String: Any] = [
                "clientDataJSON": clientDataJSONBase64,
                "authenticatorData": authenticatorData,
                "signature": signature,
                "userHandle": userHandle
            ]
            
            let parameters: [String: Any] = [
                "id": credentialIDObjectBase64,
                "rawId": rawIDObject,
                "response": responseObject,
                "type": "public-key"
            ]
            
            AF.request(signInUserAPIEndpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseData { responseData in
                switch responseData.response?.statusCode {
                case 200:
                    print("Successfully signed in user usig Passkeys")
                    self.didFinishSignIn()
                    
                case .none:
                    print("Response not found \(#function)")
                    
                case .some(_):
                    print("Unknown response found: \(String(describing: responseData.response?.statusCode))")
                }
            }
            
            
        case let passwordCredential as ASPasswordCredential:
            logger.log("A password was provided: \(passwordCredential)")
            didFinishSignIn()
            
        default:
            fatalError("Received unknown authorization type")
        }
    }
    
    func signOutWebauthnUser(completionHandler: @escaping (Bool) -> Void) {
        AF.request(signOutAPIEndpoint, method: .get).responseData { responseData in
            switch responseData.response?.statusCode {
            case 200:
                print("Successfully signed out user")
                completionHandler(true)
                
            case .none:
                print("Response not found \(#function)")
                completionHandler(false)
                
            case .some(_):
                print("Unknown response: \(String(describing: responseData.response?.statusCode))")
            }
        }
    }
    
    func deleteUserAccount(completionHandler: @escaping (Bool) -> Void) {
        AF.request(deleteCredentialAPIEndpoint, method: .delete).responseData { responseData in
            switch responseData.response?.statusCode {
            case 204:
                print("Successfully deleted user account")
                completionHandler(true)
                
            case .none:
                print("Response not found \(#function)")
                completionHandler(false)
                
            case .some(_):
                print("Unknown response: \(String(describing: responseData.response?.statusCode))")
            }
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
                            self.beginWebAuthnRegistration(response: registerDataResponseDecoded)
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
        let challengeResponse = response.challenge
        let usernameDecoded = response.user.name
        let userIdDecoded = response.user.id
        
        let userId = Data(userIdDecoded.utf8)
        
        guard let challengeBase64EncodedData = challengeResponse.base64URLDecodedData() else {
            print("Error decoding challengeResponseString to Data")
            return
        }
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(
            challenge: challengeBase64EncodedData,
            name: usernameDecoded,
            userID: userId
        )
        
        let authController = ASAuthorizationController(authorizationRequests: [registrationRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests(options: .preferImmediatelyAvailableCredentials)
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
