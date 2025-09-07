import Foundation
import SwiftData

@Model
final class Configuration {
    var serverURL: String
    var token: String
    var createdAt: Date
    
    init(serverURL: String = "", token: String = "") {
        self.serverURL = serverURL
        self.token = token
        self.createdAt = Date()
    }
    
    var isConfigured: Bool {
        !serverURL.isEmpty && !token.isEmpty
    }
}