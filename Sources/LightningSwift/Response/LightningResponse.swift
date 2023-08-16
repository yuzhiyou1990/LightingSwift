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

public struct InvoiceResponse: Codable {
    public let rHash: rHash
    public let paymentRequest: String
    public let addIndex: String
    public let payReq: String
    public let description: String?
    public let paymentHash: String?
    public let amt: UInt64?
    public let expireTime: Int?
    public let timestamp: Int?
    public let type: String?
    
    public struct rHash: Codable {
        public let type: String
        public let data: [UInt8]
    }
}

public struct DecodeInvoiceResponse: Codable {
    public let destination: String
    public let paymentHash: String
    public let numSatoshis: String
    public let timestamp: String
    public let expiry: String
    public let description: String
    public let descriptionHash: String
    public let fallbackAddr: String
    public let cltvExpiry: String
    public let numMsat: String
}
