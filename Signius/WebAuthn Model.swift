// MARK: - Sing up

struct BeginWebAuthnRegistrationResponse: Codable {
    let rp: Rp
    let timeout: Int
    let attestation: String
    let pubKeyCredParams: [PubKeyCredParam]
    let challenge: String
    let user: User
}

struct PubKeyCredParam: Codable {
    let type: String
    let alg: Int
}

struct Rp: Codable {
    let id, name: String
}

struct User: Codable {
    let id, name, displayName: String
}

// MARK: - Sing in

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
