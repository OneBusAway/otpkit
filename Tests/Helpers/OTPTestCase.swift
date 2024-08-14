//
//  OTPTestCase.swift
//  OTPKitTests
//
//  Created by Aaron Brethorst on 5/2/24.
//

import Foundation
@testable import OTPKit
import XCTest

public class OTPTestCase: XCTestCase {
    var userDefaults: UserDefaults!

    override open func setUp() {
        super.setUp()
        NSTimeZone.default = NSTimeZone(forSecondsFromGMT: 0) as TimeZone
        userDefaults = buildUserDefaults()
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    override open func tearDown() {
        super.tearDown()
        NSTimeZone.resetSystemTimeZone()
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    // MARK: - User Defaults

    func buildUserDefaults(suiteName: String? = nil) -> UserDefaults {
        UserDefaults(suiteName: suiteName ?? userDefaultsSuiteName)!
    }

    var userDefaultsSuiteName: String {
        String(describing: self)
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
