//
//  LightningNetworkService.swift
//  MathWallet5
//
//  Created by 薛跃杰 on 2023/7/10.
//

import Foundation
import PromiseKit

public struct LightningNetworkService {
    public var url: String
    private var session: URLSession
    
    public init(url: String) {
        self.url = url
        self.session = URLSession(configuration: .default)
    }
    
    public func createAccount(isTest: Bool) -> Promise<CreateAccountResponse> {
        let body = [
            "partnerid": "mathwallet",
            "accounttype": isTest ? "test" : "common"
        ]
        return POST(method: "/create", body: body)
    }
    
    public func authorize(login: String, password: String) -> Promise<AuthResponse> {
        let body = [
            "login": login,
            "password": password
        ]
        return POST(method: "/auth?type=auth", body: body)
    }
    
    public func refreshAcessToken(refreshToken: String) -> Promise<AuthResponse> {
        let body = [
            "refresh_token": refreshToken
        ]
        return POST(method: "/auth?type=refresh_token", body: body)
    }
}

extension LightningNetworkService {
    public func getBTCAddress(accessToken: String) -> Promise<String> {
        let headers = [
            "Authorization": "Bearer \(accessToken)"
        ]
        return GET(method: "/getbtc", headers: headers)
    }
    
    public func newBTCAddress() -> Promise<String> {
        return POST(method: "/newbtc")
    }
    
    public func fetchBalance(accessToken: String) -> Promise<String> {
        let headers = [
            "Authorization": "Bearer \(accessToken)"
        ]
        return GET(method: "/balance", headers: headers)
    }
    
    public func addInvoice(amt: String, memo: String = "", accessToken: String) -> Promise<String> {
        let headers = [
            "Authorization": "Bearer \(accessToken)"
        ]
        let body = [
            "amt": "\(amt) ",
            "memo": memo
        ] as [String : Any]
        return POST(method: "/payinvoice", body: body)
    }
    
    public func payInvoice(invoice: String, freeamount: UInt64 = 0, accessToken: String) -> Promise<String> {
        let headers = [
            "Authorization": "Bearer \(accessToken)"
        ]
        let body = [
            "invoice": invoice,
            "amount": freeamount
        ] as [String : Any]
        return POST(method: "/payinvoice", body: body)
    }
}

extension LightningNetworkService {
    func GET<T: Decodable>(method: String, parameters: [String: Any]? = nil, headers: [String: String] = [:]) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "lightning.get")
        queue.async {
            let path = "\(self.url)\(method)"
            guard var urlPath = URL(string: path) else {
                rp.resolver.reject(LightningError.providerError("Node error"))
                return
            }
            urlPath = urlPath.appendingQueryParameters(parameters)
            var urlRequest = URLRequest(url: urlPath, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
            urlRequest.httpMethod = "GET"
            for key in headers.keys {
                urlRequest.setValue(headers[key], forHTTPHeaderField: key)
            }
            if !headers.keys.contains("Content-Type") {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            if !headers.keys.contains("Access-Control-Allow-Origin") {
                urlRequest.setValue("*", forHTTPHeaderField: "Access-Control-Allow-Origin")
            }

            task = self.session.dataTask(with: urlRequest){ (data, response, error) in
               guard error == nil else {
                   rp.resolver.reject(error!)
                   return
               }
               guard data != nil else {
                   rp.resolver.reject(LightningError.providerError("Node response is empty"))
                   return
               }
               rp.resolver.fulfill(data!)
            }
            task?.resume()
        }
        return rp.promise.ensure(on: queue) {
            task = nil
        }.map(on: queue){ (data: Data) throws -> T in
//            debugPrint(String(data: data, encoding: .utf8) ?? "")
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let resp = try? decoder.decode(T.self, from: data) {
               return resp
            }
//            if let errorResult = try? decoder.decode(AptosClient.Error.self, from: data) {
//                throw LightningError.resoultError(errorResult.errorCode, errorResult.message)
//            }
            throw LightningError.providerError("Parameter error or received wrong message")
        }
    }
    
    func POST<T: Decodable>(method: String, parameters: [String: Any]? = nil, body: [String: Any]? = nil, headers: [String: String] = [:]) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "lightning.post")
        queue.async {
            let path = "\(self.url)\(method)"
            guard var urlPath = URL(string: path) else {
                rp.resolver.reject(LightningError.providerError("Node error"))
                return
            }
            urlPath = urlPath.appendingQueryParameters(parameters)
            var urlRequest = URLRequest(url: urlPath, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
            urlRequest.httpMethod = "POST"
            for key in headers.keys {
                urlRequest.setValue(headers[key], forHTTPHeaderField: key)
            }
            if !headers.keys.contains("Content-Type") {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            if !headers.keys.contains("Access-Control-Allow-Origin") {
                urlRequest.setValue("*", forHTTPHeaderField: "Access-Control-Allow-Origin")
            }
            if let _body = body {
                urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: _body, options: [])
            }
            
            task = self.session.dataTask(with: urlRequest){ (data, response, error) in
                guard error == nil else {
                    rp.resolver.reject(error!)
                    return
                }
                guard data != nil else {
                    rp.resolver.reject(LightningError.providerError("Node response is empty"))
                    return
                }
                rp.resolver.fulfill(data!)
            }
            task?.resume()
        }
        return rp.promise.ensure(on: queue) {
            task = nil
        }.map(on: queue){ (data: Data) throws -> T in
            //            debugPrint(String(data: data, encoding: .utf8) ?? "")
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let resp = try? decoder.decode(T.self, from: data) {
                return resp
            }
//            if let errorResult = try? decoder.decode(LightningError.self, from: data) {
//                throw LightningError.resoultError(errorResult.errorCode, errorResult.message)
//            }
            throw LightningError.providerError("Parameter error or received wrong message")
        }
    }
}

public enum LightningError: LocalizedError {
    case deserializeError
    case serializeError
    case decodingError
    case encodingError
    case providerError(String)
    case keyError(String)
    case otherEror(String)
    case resoultError(String, String)
    
    public var errorDescription: String? {
        switch self {
        case .deserializeError:
            return "Deserialize Error"
        case .serializeError:
            return "Serialize Error"
        case .decodingError:
            return "Decoding error"
        case .encodingError:
            return "Encoding error"
        case .providerError(let message):
            return message
        case .keyError(let message):
            return message
        case .otherEror(let message):
            return message
        case .resoultError(_, let message):
            return message
        }
    }
}
