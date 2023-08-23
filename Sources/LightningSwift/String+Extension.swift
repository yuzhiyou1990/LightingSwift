//
//  File.swift
//  
//
//  Created by on 2023/8/23.
//

import Foundation

extension String {
    public func urlLegalize() -> String {
        var urlStr = self
        if urlStr.last == "/" {
            urlStr.remove(at: urlStr.index(urlStr.startIndex, offsetBy: urlStr.count - 1))
        }
        return urlStr
    }
}
