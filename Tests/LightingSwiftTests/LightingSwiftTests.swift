import XCTest
@testable import LightingSwift

final class LightingSwiftTests: XCTestCase {
    let login = "3e0ebca7a39192b4c9dd"
    let password = "cc531d82f7a75649c1c9"
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
                let result = try self.service.getBTCAddress(accessToken: "").wait()
                debugPrint(result)
            } catch let error {
                debugPrint(error)
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
}
