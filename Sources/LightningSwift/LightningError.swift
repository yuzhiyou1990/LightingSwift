//
//  LightningError.swift
//    
//
//  Created by   xgblin on 2023/8/14.
//

import Foundation

public enum LightningError: LocalizedError {
    case other(String)
    case unknow
    
    public var errorDescription: String? {
        switch self {
        case .other(let message):
            return message
        case .unknow:
            return "unknow"
        }
    }
}

public enum LightningServiceError: LocalizedError {
    case authError
    case providerError(String)
    case resoultError(Int, String)
    
    public var errorDescription: String? {
        switch self {
        case .authError:
            return "auth Error"
        case .providerError(let message):
            return message
        case .resoultError(_, let message):
            return message
        }
    }
}
