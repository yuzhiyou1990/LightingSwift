//
//  File.swift
//  
//
//  Created by xgblin on 2023/7/13.
//

import Foundation
import AnyCodable

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
    public var category: String?
    public var amount: Float?
    public var confirmations: Int?
    public var address: String?
    public var time: Int?
    public var timestamp: AnyCodable?
    public var value: Int64?
    public var type: String
    public var memo: String?
    public var fee: Int64?
    public var timeInt64: Int64 {
        if let _time = time {
            return Int64(_time)
        } else {
            if let _timestamp = timestamp {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                if let timeString = try? decoder.decode(String.self, from: JSONEncoder().encode(timestamp)) {
                    return Int64(timeString) ?? 0
                } else {
                    if let timeInt64 = try? decoder.decode(Int64.self, from: JSONEncoder().encode(timestamp)) {
                        return timeInt64
                    }
                }
            }
        }
        return 0
    }
    
    public init(category: String? = nil, amount: Float? = nil, confirmations: Int? = nil, address: String? = nil, time: Int? = nil, timestamp: AnyCodable? = nil, value: Int64? = nil, type: String, memo: String? = nil, fee: Int64? = nil) {
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
    public let ispaid: Bool?
    
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
