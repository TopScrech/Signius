//import Foundation
//
//func revokeAppleToken(clientID: String, clientSecret: String, token: String, completion: @escaping (Bool, Error?) -> Void) {
//    let url = URL(string: "https://appleid.apple.com/auth/revoke")!
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    
//    let body = [
//        "client_id": clientID,
//        "client_secret": clientSecret,
//        "token": token
//    ]
//    
//    request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
//    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//    
//    URLSession.shared.dataTask(with: request) { data, response, error in
//        if let error {
//            completion(false, error)
//            return
//        }
//        
//        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
//            completion(true, nil)
//        } else if let httpResponse = response as? HTTPURLResponse {
//            completion(false, NSError(domain: "", code: httpResponse.statusCode, userInfo: nil))
//        }
//    }.resume()
//}
