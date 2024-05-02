//
//  OTPKitTests.swift
//  OTPKitTests
//
//  Created by Aaron Brethorst on 5/2/24.
//

import XCTest
@testable import OTPKit

class OTPKitTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testHello() {
        let restApi = RestAPI()
        XCTAssertEqual(restApi.hello(), "Hello, OTPKit!")
    }
}
