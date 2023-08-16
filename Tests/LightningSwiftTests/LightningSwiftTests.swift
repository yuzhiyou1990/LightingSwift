import XCTest
@testable import LightningSwift

final class LightningSwiftTests: XCTestCase {
    let login = "b07371ac5a9e4cc21ce3"
    let password = "70e7f3f3b14f8bf8b9d8"
    let refreshToken = "7cd32a5ddfe6b3ca2cf60f89f6ac6ef02d7c21e4"
    let accessToken = "33a8a689a8a50bf7b09c334562e578d044f54db0"
    let service = LightningNetworkService(url: "https://lnd.maiziqianbao.net")
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results
    }
    
    func testCreatExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let result = try self.service.createAccount(isTest: true).wait()
                debugPrint(result)
            } catch let error {
                debugPrint(error)
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testAuthorizeExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let result = try self.service.authorize(login: self.login, password: self.password).wait()
                debugPrint(result)
            } catch let error {
                debugPrint(error)
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testGetAddressExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let result = try self.service.getBTCAddress(accessToken: self.accessToken).wait()
                debugPrint(result)
            } catch let error {
                debugPrint(error)
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testAddInvoiceExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let result = try self.service.addInvoice(amt: "2", accessToken: self.accessToken).wait()
                debugPrint(result)
            } catch let error {
                debugPrint(error)
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testGetInvoicesExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let result = try self.service.getUserInvoices(accessToken: self.accessToken).wait()
                debugPrint(result)
            } catch let error {
                debugPrint(error)
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testDecodeInvoicesExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let result = try self.service.decodeInvoice(invoice: "lnbc200n1pjdrfjkpp55m36n0rj0t9ekfwtaca2cmppv899l2atk5fgure67yjvafrgt4esdqyw3jscqzzsxqyz5vqsp56qet75r7k2gvauud0pcldug67f6k4mvzg5jmazjgwk2yeu7srhus9qyyssquk87rptz3rgqp6tfhgxlxawy68tw8pwdagazz4vwjj0r7urjxr8hsluhc7kfe7zx5xkltqg5ttavqg2h4hyh9dxg3l58rqdxvp95vxqp0zuay0", accessToken: self.accessToken).wait()
                debugPrint(result)
            } catch let error {
                debugPrint(error)
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testLnurlExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let result = try LightningDecodeInvoiceService.decodeLNURL(LNURL: "LNURL1DP68GURN8GHJ7EM9W3SKCCNE9E3K7MF0D3H82UNVWQHHGAMFD35KW6R5D4HHYMNFDENNYWF4XYCS59VCHV").wait()
                debugPrint(result)
            } catch let error {
                debugPrint(error)
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testLightningAddressExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let result = try LightningDecodeInvoiceService.decodeLightningAddress(address: "twilightmorning29511@getalby.com").wait()
                debugPrint(result)
            } catch let error {
                debugPrint(error)
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
}
