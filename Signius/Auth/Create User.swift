import Foundation

func createUser(name: String, email: String, complition: @escaping (Result<User, Error>) -> Void) {
    let url = URL(string: "http://api.topscrech.dev/users/create")!
    var request = URLRequest(url: url)
    
    let body = ["name": name, "email": email]
    let encoder = JSONEncoder()
    
    request.httpMethod = "POST"
    request.httpBody = try? encoder.encode(body)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error {
            complition(.failure(error))
            return
        }
        
        guard let data else {
            return complition(.failure(Errors.noDataRecieved))
        }
        
        do {
            let decoder = JSONDecoder()
            let user = try decoder.decode(User.self, from: data)
            
            if let stringData = String(data: data, encoding: .utf8) {
                print(stringData)
            }
            
            return complition(.success(user))
        } catch {
            
            return complition(.failure(Errors.unknownError))
        }
    }.resume()
}
