import Foundation
import CryptoKit

func sendAuthenticationDataToServer(passkey: String?, credentialId: String) {
    guard let url = URL(string: "http://49.13.93.214:1889/authify/create") else {
        return
    }
    
    guard let passkey else {
        print("Bad passkey")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body = [
        "name": "Hitlet",
        "passkey": passkey,
        "passkey_id": credentialId
    ]
    
    do {
        //        let jsonData = try JSONSerialization.data(withJSONObject: credentialId, options: [])
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print("Error sending authentication data: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response from server")
                return
            }
            
            // Handle successful authentication response here
            print("Successfully authenticated with the server.")
        }
        
        task.resume()
    } catch {
        print("Failed to serialize auth data: \(error)")
    }
}

func checkRequestServer(_ credentialId: String, signature: Data?, clientDataJSON: Data) {
    guard let url = URL(string: "http://49.13.93.214:1889/authify/login") else {
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["passkey_id": credentialId]
    
    do {
        request.httpBody = try JSONEncoder().encode(body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print("Error sending authentication data: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response from server")
                return
            }
            
            print("Successfully authenticated with the server.")
            
            // Handle the successful response
            if let data = data {
                // Convert the data to a string
                guard let responseString = String(data: data, encoding: .utf8) else {
                    print("Failed to decode response data as string")
                    return
                }
                
                print("Server response: \(responseString)")
                
                if let publicKey = Data(base64Encoded: responseString) {
                    print("Decoded Public Key Data: \(publicKey as NSData)")
                    
                    let result = verifySignature(
                        storedPublicKey: publicKey,
                        signature: signature,
                        clientDataJSON: clientDataJSON
                    )
                    //{"type":"webauthn.create","challenge":"epHauhdqsQHN0CX4sjcwu-_ZLjsWaNtzOsj-3RhJN9M","origin":"https://topscrech.dev"}
                    //{"type":"webauthn.get","challenge":"ySMBiyN6k5ynb0u4ud-zSsSf7XkAh9tfKwy01hTpIrA","origin":"https://topscrech.dev"}
                    
                    print("Signature verification result: \(result)")
                } else {
                    print("Failed to decode response data as base64 string")
                }
            }
        }
        
        task.resume()
    } catch {
        print("Failed to serialize auth data: \(error)")
    }
}

func verifySignature(storedPublicKey: Data, signature: Data?, clientDataJSON: Data) -> Bool {
    guard let signature else {
        print("Invalid signature")
        return false
    }
    
    // Print the public key data to inspect it
    print("Stored Public Key Data: \(storedPublicKey as NSData)")
    
    // Check if the public key can be created from X.963 format
    do {
        let publicKey = try P256.Signing.PublicKey(x963Representation: storedPublicKey)
        
        // Create the SHA256 hash of the clientDataJSON
        let hash = SHA256.hash(data: clientDataJSON)
        
        // Verify the signature using the public key
        let signature = try P256.Signing.ECDSASignature(derRepresentation: signature)
        let isValid = publicKey.isValidSignature(signature, for: hash)
        print("Signature valid: \(isValid)")
        return isValid
    } catch {
        // Detailed error logging
        print("Error in public key conversion or signature verification: \(error.localizedDescription)")
        return false
    }
}
