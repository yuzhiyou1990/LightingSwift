//
//  Bolt11.swift

//
//  Created by xgblin on 2023/8/4.
//

import Foundation
import BigInt
import CryptoSwift

public struct Bolt11 {
    static let DEFAULTEXPIRETIME = 3600
    static let DEFAULTCLTVEXPIRY = 9
    static let DEFAULTDESCRIPTION = ""
    static let DEFAULTFEATUREBITS = [
        "wordLength": 4,
        "varOnionOptin": [
            "required": false,
            "supported": true
        ],
        "paymentSecret": [
            "required": false,
            "supported": true
        ]
    ] as [String : Any]
    static let FEATUREBIT_ORDER = [
        "optionDataLossProtect",
        "initialRoutingSync",
        "optionUpfrontShutdown_script",
        "gossipQueries",
        "varOnionOptin",
        "gossipQueries_ex",
        "optionStaticRemotekey",
        "paymentSecret",
        "basicMpp",
        "optionSupportLargeChannel"
    ]

    static let DIVISORS = [
        "m": BigInt("1000"),
        "u": BigInt("1000000"),
        "n": BigInt("1000000000"),
        "p": BigInt("1000000000000")
    ]
    static let MAX_MILLISATS = BigInt("2100000000000000000")
    static let MILLISATS_PER_BTC = BigInt("100000000000")
    static let MILLISATS_PER_MILLIBTC = BigInt("100000000")
    static let MILLISATS_PER_MICROBTC = BigInt("100000")
    static let MILLISATS_PER_NANOBTC = BigInt("100")
    static let PICOBTC_PER_MILLISATS = BigInt("10")
    static let TAGCODES = [
        "paymentHash": 1,
        "paymentSecret": 16,
        "description": 13,
        "payeeNodeKey": 19,
        "purposeCommitHash": 23,
        "expireTime": 6,
        "minFinalCltvExpiry": 24,
        "fallbackAddress": 9,
        "routingInfo": 3,
        "featureBits": 5
    ]
    static let TAGNAMES: [String: String] = TAGCODES.reduce(into: [:]) { (result, element) in
        result[element.value.description] = element.key
    }

    static func TAGPARSER(tagCode: Int, words: [UInt8]) throws -> Any? {
        switch tagCode {
        case 1, 16, 19, 23:
            return try wordsToBuffer(words: words, trim: true).toHexString()
        case 13:
            return String(bytes: try wordsToBuffer(words: words, trim: true), encoding: .utf8)
        case 6, 24:
            return wordsToIntBE(words: words)
        default:
            return nil
        }
    }

    static let unknownTagName = "unknownTag"

    public static func decode(invoice: String /*network: MainNetParams*/) throws -> DecodeInvoiceResponse {

        guard invoice.lowercased().starts(with: "ln") else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not a proper lightning payment request"])
        }

        let (prefix, checksum) = try Bech32().decode(invoice, length: Int.max)
        var words = checksum.bytes
        let sigWords = Array(words.suffix(104))
        let wordsNoSig = Array(words[0..<words.count - 104])
        words = Array(words[0..<words.count - 104])

        var sigBuffer = try wordsToBuffer(words: sigWords, trim: true)
        let recoveryFlag = sigBuffer.removeLast()
        
        if ![0, 1, 2, 3].contains(recoveryFlag) || sigBuffer.count != 64 {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Signature is missing or incorrect"])
        }
        
        let prefixMatches: [String]? = {
            let prefixPattern = "^ln(\\S+?)(\\d*)([a-zA-Z]?)$"
            if let matchesRange = prefix.range(of: prefixPattern, options: .regularExpression) {
                let matchedSubstring = String(prefix[matchesRange])
                let regex = try? NSRegularExpression(pattern: prefixPattern, options: [])
                if let match = regex?.matches(in: matchedSubstring, options: [], range: NSRange(matchedSubstring.startIndex..., in: matchedSubstring)).first {
                    let groupCount = match.numberOfRanges
                    var groupValues: [String] = []
                    for groupIndex in 0..<groupCount {
                        let groupRange = match.range(at: groupIndex)
                        if groupRange.location != NSNotFound, let range = Range(groupRange, in: matchedSubstring) {
                            let groupValue = String(matchedSubstring[range])
                            groupValues.append(groupValue)
                        }
                    }
                    return groupValues
                }
            }
            return nil
        }()
        
        guard let net = prefixMatches?[1], ["bc", "tb", "sb"].contains(net) else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid network"])
        }

        var satoshis: Int64 = 0
        var millisatoshis = BigInt.zero
        let value = prefixMatches?[2] ?? ""
        let divisor = prefixMatches?[3] ?? ""
        
        if value.isEmpty {
            satoshis = 0
            millisatoshis = BigInt(0)
        } else {
            do {
                satoshis = try Int64(hrpToSat(hrpString: "\(value)\(divisor)"))
            } catch {
                satoshis = 0
            }
            millisatoshis = try hrpToMillisat(hrpString: "\(value)\(divisor)")
        }

        let timestamp = wordsToIntBE(words: Array(words[0..<7]))
        let timestampString = String(describing: Date(timeIntervalSince1970: TimeInterval(timestamp)))

        words = Array(words[7...]) // trim off the left 7 words

        var tags = [LightningParserTag]()
        var tagName = ""
        var parser = ""
        var tagLength = 0
        var tagWords = [UInt8]()
        var description = ""
        var payment_hash = ""
        
        while !words.isEmpty {
            let tagCode = words[0]
            tagName = TAGNAMES[String(tagCode)] ?? unknownTagName
            words.removeFirst()

            tagLength = Int(wordsToIntBE(words: Array(words[0..<2])))
            words = Array(words[2...])

            tagWords = Array(words[0..<tagLength])

            let parserTagWords = try TAGPARSER(tagCode: Int(tagCode), words: tagWords) ?? getUnknownParser(tagCode: Int(tagCode), words: tagWords)

            if tagCode == 13 && tagName == "description" {
                description = parserTagWords as! String
            }

            if tagCode == 1 && tagName == "paymentHash" {
                payment_hash = parserTagWords as! String
            }

            words = Array(words[tagLength...])

            let tag = LightningParserTag(tagCode: Int(tagCode), tagName: tagName, data: parserTagWords)

            tags.append(tag)
        }

        // 判断过期时间
        for lightningParserTag in tags {
            if lightningParserTag.tagCode == 6 {
                let timeExpireDate = timestamp + (lightningParserTag.data as! Int64)
                let timeExpireDateString = String(describing: Date(timeIntervalSince1970: TimeInterval(timeExpireDate)))
                if timeExpireDate < Int64(Date().timeIntervalSince1970) {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invoice has expired"])
                } else {
                    break
                }
            }
        }

        // 判断签名
        let convert = try convert(data: wordsNoSig, inBits: 5, outBits: 8, pad: true)
        let prefixData = prefix.data(using: .utf8)!
        let toSign = prefixData + Data(convert)
        let payReqHash = toSign.sha256()

        let sigPubkey = [UInt8]() // This part is commented out since we need a crypto library to perform ECDSA recovery.

        for lightningParserTag in tags {
            if lightningParserTag.tagCode == 19 {
                let data = lightningParserTag.data as! String
                if data != sigPubkey.toHexString() {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Lightning Payment Request signature pubkey does not match payee pubkey"])
                } else {
                    break
                }
            }
        }

        return DecodeInvoiceResponse(destination: "", paymentHash: payment_hash, numSatoshis: String(satoshis), timestamp: String(timestamp), expiry: "", description: description, descriptionHash: "", fallbackAddr: "", cltvExpiry: "", numMsat: "")
    }
    
    static func convert(data: [UInt8], inBits: Int, outBits: Int, pad: Bool) throws -> [UInt8] {
        var value = BigUInt(0)
        var bits = 0
        let maxV = BigUInt((1 << outBits) - 1)
        var result: [UInt8] = []

        for i in 0..<data.count {
            let unsigned = BigUInt(data[i])
            value = value << inBits | unsigned
            bits += inBits
            while bits >= outBits {
                bits -= outBits
                let shiftedValue = value >> bits
                result.append(UInt8(shiftedValue & maxV))
            }
        }

        if pad {
            if bits > 0 {
                result.append(UInt8(value << (outBits - bits) & maxV))
            }
        } else {
            if bits >= inBits {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Excess padding"])
            }
            if value << (outBits - bits) & maxV > 0 {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Non-zero padding"])
            }
        }

        return result
    }

    static func fromWords(words: [UInt8]) throws -> [UInt8] {
        return try convert(data: words, inBits: 5, outBits: 8, pad: false)
    }
    
    static func wordsToIntBE(words: [UInt8]) -> Int64 {
        var total: Int64 = 0
        for (index, item) in words.reversed().enumerated() {
            total += Int64(item) * Int64(pow(32.0, Double(index)))
        }
        return total
    }

    static func wordsToBuffer(words: [UInt8], trim: Bool) throws -> [UInt8] {
        var fromWords = try convert(data: words, inBits: 5, outBits: 8, pad: true)
        if trim && words.count * 5 % 8 != 0 {
            fromWords = Array(fromWords[0..<fromWords.count - 1])
        }
        return fromWords
    }

    static func hrpToSat(hrpString: String) throws -> Int64 {
        let millisatoshisBN = try hrpToMillisat(hrpString: hrpString)
        guard millisatoshisBN % BigInt(1000) == BigInt(0) else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Amount is outside of valid range"])
        }
        return Int64(millisatoshisBN / BigInt(1000))
    }

    static func hrpToMillisat(hrpString: String) throws -> BigInt {
        var divisor = ""
        var value = "0"
        let lastIndexString = hrpString.suffix(1)
        let matches = try NSRegularExpression(pattern: "^[munp]$").matches(in: String(lastIndexString), options: [], range: NSRange(location: 0, length: lastIndexString.utf16.count))
        if matches.isEmpty {
            value = hrpString
        } else if let range = hrpString.range(of: "[munp]$", options: .regularExpression) {
            divisor = String(hrpString[range])
            value = String(hrpString[..<range.lowerBound])
        } else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not a valid multiplier for the amount"])
        }

        guard let valueBN = BigInt(value, radix: 10) else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not a valid human-readable amount"])
        }

        var millisatoshisBN: BigInt
        if divisor.isEmpty {
            millisatoshisBN = valueBN * MILLISATS_PER_BTC
        } else {
            guard let divisorBN = DIVISORS[divisor] else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not a valid human-readable amount"])
            }
            millisatoshisBN = valueBN * MILLISATS_PER_BTC / divisorBN
        }

        if (divisor == "p" && valueBN % BigInt(10) != BigInt(0)) || millisatoshisBN > MAX_MILLISATS {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Amount is outside of valid range"])
        }

        return millisatoshisBN
    }

    public static func getUnknownParser(tagCode: Int, words: [UInt8]) -> String {
        return Bech32().encode("unknow", values: Data(words))
    }
}

struct LightningParserTag {
    let tagCode: Int
    let tagName: String
    let data: Any?
}
