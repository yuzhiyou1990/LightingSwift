//
//  LightningDecodeInvoiceService.swift
//    
//
//  Created by   xgblin on 2023/8/15.
//

import Foundation
import PromiseKit
import BigInt

struct LightningDecodeInvoiceService {
    static func decodeInvoice(invoice: String, url: String, accessToken: String) -> Promise<DecodeInvoiceResponse> {
        let (promise, seal) = Promise<DecodeInvoiceResponse>.pending()
        LightningNetworkService(url: url).decodeInvoice(invoice: invoice, accessToken: accessToken).done { decodeInvoiceResponse in
            seal.fulfill(decodeInvoiceResponse)
        }.catch { _ in
            do {
                var decodeInvoiceResponse = try Bolt11.decode(invoice: invoice)
                decodeInvoiceResponse.invoice = invoice
                seal.fulfill(decodeInvoiceResponse)
            } catch let error {
                seal.reject(error)
            }
        }
        return promise
    }
    
    static func decodeLNURL(LNURL: String) -> Promise<LNUrlMetadataResponse> {
        let (promise, seal) = Promise<LNUrlMetadataResponse>.pending()
        do {
            let (_, checksum) = try Bech32().decode(LNURL, length: Int.max)
            let urlData = try Bolt11.fromWords(words: checksum.bytes)
            guard let lnUrl = String(data: Data(urlData), encoding: .utf8), let url = URL(string: lnUrl) else {
                throw LightningError.other("invoice decode error")
            }
            let domin = "\(url.scheme ?? "")://\(url.host ?? "")"
            let path = url.path
            LightningNetworkService.getLightningLNURLMetadata(urlString: domin, path: path).done { LNUrlMetadata in
                seal.fulfill(LNUrlMetadata)
            }.catch { error in
                seal.reject(error)
            }
        } catch let error {
            seal.reject(error)
        }
        return promise
    }
    
    static func decodeLightningAddress(address: String) -> Promise<LNUrlMetadataResponse> {
        let (promise, seal) = Promise<LNUrlMetadataResponse>.pending()
        let host = address.components(separatedBy: "@")[1]
        let path = address.components(separatedBy: "@")[0]
        let baseUrl = "https://\(host)"
        let pathUrl = "/lnurlp/\(path)"
        LightningNetworkService.getLightningLNURLMetadata(urlString: baseUrl, path: pathUrl).done { LNUrlMetadata in
            seal.fulfill(LNUrlMetadata)
        }.catch { error in
            seal.reject(error)
        }
        return promise
    }
    
    public static func getCallBackInvoice(amount: String) -> Promise<LNUrlCallbackInvoiceResponse> {
        let url = URL(string: "callback")
        let baseUrl = "\(url?.scheme ?? "")://\(url?.host ?? "")"
        let path = url?.path ?? ""
        let amountBigInt = BigInt(amount)
        let lnAmount = amountBigInt! * BigInt(1000)
        return LightningNetworkService.getLightningLNUrlCallbackInvoice(baseUrl: baseUrl, path: path, amount: lnAmount.description)
    }
}
