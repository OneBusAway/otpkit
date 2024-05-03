//
//  OTPTestCase.swift
//  OTPKitTests
//
//  Created by Aaron Brethorst on 5/2/24.
//

import Foundation
import XCTest
@testable import OTPKit

public class OTPTestCase: XCTestCase {

    var userDefaults: UserDefaults!

    open override func setUp() {
        super.setUp()
        NSTimeZone.default = NSTimeZone(forSecondsFromGMT: 0) as TimeZone
        userDefaults = buildUserDefaults()
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    open override func tearDown() {
        super.tearDown()
        NSTimeZone.resetSystemTimeZone()
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    // MARK: - User Defaults

    func buildUserDefaults(suiteName: String? = nil) -> UserDefaults {
        UserDefaults(suiteName: suiteName ?? userDefaultsSuiteName)!
    }

    var userDefaultsSuiteName: String {
        return String(describing: self)
    }

    // MARK: - Network and Data

    func buildMockDataLoader() -> MockDataLoader {
        MockDataLoader(testName: name)
    }

    func buildRestAPIClient(
        baseURLString: String = "https://otp.prod.sound.obaweb.org/otp/routers/default/"
    ) -> RestAPI {
        let baseURL = URL(string: baseURLString)!
        return RestAPI(baseURL: baseURL, dataLoader: buildMockDataLoader())
    }
}
