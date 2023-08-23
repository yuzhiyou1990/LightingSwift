//
//  File.swift
//  
//
//  Created by xgblin on 2023/7/13.
//

import Foundation

public struct CreateAccountResponse: Codable {
    public let login: String
    public let password: String
    
    public var secret: String {
        return "lndhub://\(login):\(password)"
    }
}

public struct InfoResponse: Codable {
    public let chains: [InfoChains]
    public let identityPubkey: String
    public let blockHeight: Int64
    
    public struct InfoChains: Codable {
        public let chain: String
        public let network: String
    }
}

public struct AuthResponse: Codable {
    public let refreshToken: String
    public let accessToken: String
}

public struct BTCAddress: Codable {
    public let address: String
}

public struct BalanceResponse: Codable {
    public let BTC: BalanceObject
    
    public struct BalanceObject: Codable {
        public let AvailableBalance: Int64
    }
}

public struct TransactionResponse: Codable {
    public let category: String?
    public let amount: Float?
    public let confirmations: Int?
    public let address: String?
    public let time: Int?
    public let timestamp: Int?
    public let value: Int64?
    public let type: String
    public let memo: String?
    public let fee: Int64?
    
    public init(category: String?, amount: Float?, confirmations: Int?, address: String?, time: Int?, timestamp: Int?, value: Int64?, type: String, memo: String?, fee: Int64?) {
        self.category = category
        self.amount = amount
        self.confirmations = confirmations
        self.address = address
        self.time = time
        self.timestamp = timestamp
        self.value = value
        self.type = type
        self.memo = memo
        self.fee = fee
    }
}

public struct InvoiceResponse: Codable {
    public let rHash: RHash
    public let paymentRequest: String
    public let addIndex: String
    public let payReq: String
    public let description: String?
    public let paymentHash: String?
    public let amt: Int64?
    public let expireTime: Int?
    public let timestamp: Int?
    public let type: String?
    
    public struct RHash: Codable {
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
    
    public var invoice: String?
}

public struct LNUrlMetadataResponse: Codable {
    public let status: String
    public let tag: String
    public let commentAllowed: Int
    public let callback: String
    public let metadata: String
    public let minSendable: UInt64
    public let maxSendable: UInt64
    public let nostrPubkey: String
    public let allowsNostr: Bool
}

public struct LNUrlCallbackInvoiceResponse: Codable {
    public let status: String
    public let verify: String
    public let pr: String
}

public struct PayInvoiceResponse: Codable {
    public let paymentError: String
    public let payReq: String
}

public struct GetFeeResponse: Codable {
    public let routes: [GetFeeRoute]
    
    public struct GetFeeRoute: Codable {
        public let totalFees: String
    }
}

public struct NetworkError: Codable {
    public let error: Bool
    public let code: Int
    public let message: String
}
