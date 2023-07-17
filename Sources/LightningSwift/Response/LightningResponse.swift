//
//  File.swift
//  
//
//  Created by 薛跃杰 on 2023/7/13.
//

import Foundation

public struct CreateAccountResponse: Codable {
    public let login: String
    public let password: String
    
    public var secret: String {
        return "lndhub://\(login):\(password)"
    }
}

public struct AuthResponse: Codable {
    public let refreshToken: String
    public let accessToken: String
}
