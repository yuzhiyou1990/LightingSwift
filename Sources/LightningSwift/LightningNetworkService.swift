//
//  LightningNetworkService.swift

//
//  Created by xgblin on 2023/7/10.
//

import Foundation
import PromiseKit

public struct LightningNetworkService {
    public var url: String
    private var session: URLSession
    
    public init(url: String) {
        self.url = url.urlLegalize()
        self.session = URLSession(configuration: .default)
    }
    
    public func getInfo(accseeToken: String) -> Promise<InfoResponse> {
        return GETWithAccessToken(method: "/getinfo", accessToken: accseeToken)
    }
    
    public func createAccount(isTest: Bool) -> Promise<CreateAccountResponse> {
        let body = [
            "partnerid": "",
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
    public func getBTCAddress(accessToken: String) -> Promise<[BTCAddress]> {
        return GETWithAccessToken(method: "/getbtc", accessToken: accessToken)
    }
    
    public func newBTCAddress() -> Promise<String> {
        return POST(method: "/newbtc")
    }
    
    public func fetchBalance(accessToken: String) -> Promise<BalanceResponse> {
        return GETWithAccessToken(method: "/balance", accessToken: accessToken)
    }
    
    public func getFee(from: String, to: String, amount: String) -> Promise<GetFeeResponse> {
        return GET(method: "/queryroutes/\(from)/\(to)/\(amount)")
    }
    
    public func getTxs(accessToken: String) -> Promise<[TransactionResponse]> {
        return GETWithAccessToken(method: "/gettxs", accessToken: accessToken)
    }
    
    public func getTx(accessToken: String, txId: Int) -> Promise<TransactionResponse> {
        return GETWithAccessToken(method: "/gettx?txid=\(txId)", accessToken: accessToken)
    }
    
    public func getUserInvoices(accessToken: String) -> Promise<[InvoiceResponse]> {
        return GETWithAccessToken(method: "/getuserinvoices", accessToken: accessToken)
    }
}

// invoice
extension LightningNetworkService {
    public func addInvoice(amt: String, memo: String = "", accessToken: String) -> Promise<InvoiceResponse> {
        let body = [
            "amt": amt,
            "memo": memo
        ]
        return POSTWithAccessToken(method: "/addinvoice", accessToken: accessToken, body: body)
    }
    
    public func payInvoice(invoice: String, freeamount: UInt64 = 0, accessToken: String) -> Promise<PayInvoiceResponse> {
        let body = [
            "invoice": invoice,
            "amount": freeamount
        ] as [String : Any]
        return POSTWithAccessToken(method: "/payinvoice", accessToken: accessToken, body: body)
    }
    
    public func decodeInvoice(invoice: String, accessToken: String) -> Promise<DecodeInvoiceResponse> {
        return GETWithAccessToken(method: "/decodeinvoice?invoice=\(invoice)", accessToken: accessToken)
    }
    
    public static func getLightningLNURLMetadata(urlString: String, path: String) -> Promise<LNUrlMetadataResponse> {
        return LightningNetworkService(url: urlString).GET(method: path)
    }
    
    public static func getLightningLNUrlCallbackInvoice(baseUrl: String, path: String, amount: String) -> Promise<LNUrlCallbackInvoiceResponse> {
        return  LightningNetworkService(url: baseUrl).GET(method: "\(path)?amount=\(amount)")
    }
}
extension LightningNetworkService {
    
    func GETWithAccessToken<T: Decodable>(method: String, accessToken: String, parameters: [String: Any]? = nil) -> Promise<T> {
        return Promise<T> { seal in
            if accessToken.count == 0 {
                seal.reject(LightningError.other("AccessToken error"))
            }
            GET(method: method, parameters: parameters, headers: ["Authorization": "Bearer \(accessToken)"]).done { response in
                seal.fulfill(response)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func POSTWithAccessToken<T: Decodable>(method: String, accessToken: String, parameters: [String: Any]? = nil, body: [String: Any]? = nil) -> Promise<T> {
        return Promise<T> { seal in
            if accessToken.count == 0 {
                seal.reject(LightningError.other("AccessToken error"))
            }
            POST(method: method, parameters: parameters, body: body, headers: ["Authorization": "Bearer \(accessToken)"]) .done { response in
                seal.fulfill(response)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func GET<T: Decodable>(method: String, parameters: [String: Any]? = nil, headers: [String: String] = [:]) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "lightning.get")
        queue.async {
            let path = "\(url)\(method)"
            guard var urlPath = URL(string: path) else {
                rp.resolver.reject(LightningServiceError.providerError("Node error"))
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
                    rp.resolver.reject(LightningServiceError.providerError("Node response is empty"))
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
            if let errorResult = try? decoder.decode(NetworkError.self, from: data) {
                if errorResult.message == "bad auth" {
                    throw LightningServiceError.authError
                } else {
                    throw LightningServiceError.resoultError(errorResult.code, errorResult.message)
                }
            }
            throw LightningServiceError.providerError("Parameter error or received wrong message")
        }
    }
    
    func POST<T: Decodable>(method: String, parameters: [String: Any]? = nil, body: [String: Any]? = nil, headers: [String: String] = [:]) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "lightning.post")
        queue.async {
            let path = "\(url)\(method)"
            guard var urlPath = URL(string: path) else {
                rp.resolver.reject(LightningServiceError.providerError("Node error"))
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
                    rp.resolver.reject(LightningServiceError.providerError("Node response is empty"))
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
            if let errorResult = try? decoder.decode(NetworkError.self, from: data) {
                if errorResult.message == "bad auth" {
                    throw LightningServiceError.authError
                } else {
                    throw LightningServiceError.resoultError(errorResult.code, errorResult.message)
                }
            }
            throw LightningServiceError.providerError("Parameter error or received wrong message")
        }
    }
}
