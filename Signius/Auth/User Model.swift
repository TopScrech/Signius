import Foundation

struct User: Codable {
    let id: Int?
    let name: String
    let email: String
    
    init(id: Int? = nil, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}
