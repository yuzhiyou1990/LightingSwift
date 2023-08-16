//
//  LightningDecodeInvoiceService.swift
//  MathWallet5
//
//  Created by 薛跃杰 on 2023/8/15.
//

import Foundation
import PromiseKit

struct LightningDecodeInvoiceService {
    static func decodeInvoice(invoice: String, provider: LightningProvider) -> Promise<DecodeInvoiceResponse> {
        let (promise, seal) = Promise<DecodeInvoiceResponse>.pending()
        provider.decodeInvoice(invoice: invoice).done { decodeInvoiceResponse in
            seal.fulfill(decodeInvoiceResponse)
        }.catch { error in
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
    
    static func decodeLNURL(LNURL: String) -> Promise<String> {
        let (promise, seal) = Promise<String>.pending()
        do {
            let (_, checksum) = try Bech32().decode(LNURL)
            guard let lnUrl = String(data: checksum, encoding: .utf8), let url = URL(string: lnUrl) else {
                throw LightningError.other("invoice decode error")
            }
//                let domin = "\(url.protocol)://\(url?.host)"
            let domin = "\(url.scheme ?? "")://\(url.host ?? "")"
            let path = url.path
            LightningNetworkService.getLightningLNUrlMetadata(urlString: domin, path: path).done { decodeInvoiceResponse in
                seal.fulfill("")
            }.catch { error in
                seal.reject(error)
            }
        } catch let error {
            seal.reject(error)
        }
        return promise
    }
    
    static func decodeLightningAddress(address: String) -> Promise<String> {
        let (promise, seal) = Promise<String>.pending()
        let host = address.components(separatedBy: "@")[1]
        let path = address.components(separatedBy: "@")[0]
        let baseUrl = "https://\(host)"
        let pathUrl = "/lnurlp/\(path)"
        LightningNetworkService.getLightningLNUrlMetadata(urlString: baseUrl, path: pathUrl).done { decodeInvoiceResponse in
            seal.fulfill("")
        }.catch { error in
            seal.reject(error)
        }
        return promise
    }
    
    public static func getCallBackInvoice( amount: String) {
        let url = URL(string: "callback")
        let baseUrl = "\(url?.scheme ?? "")://\(url?.host ?? "")"
        let path = url?.path ?? ""
//        HttpRequestCoroutine.getLightningLNUrlCallbackInvoice(
//                           baseUrl,
//                           path,
//                           //  amount需要乘1000 转成 mstas
//                           BigDecimal(transaction.value).multiply(BigDecimal("1000")).stripTrailingZeros()
//                               .toPlainString()
//                       )
    }
}
