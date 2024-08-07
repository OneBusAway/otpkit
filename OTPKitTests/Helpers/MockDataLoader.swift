/*
 * Copyright (C) Open Transit Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import OTPKit

typealias MockDataLoaderMatcher = (URLRequest) -> Bool

struct MockDataResponse {
    let data: Data?
    let urlResponse: URLResponse?
    let error: Error?
    let matcher: MockDataLoaderMatcher
}

class MockTask: URLSessionDataTask {
    override var progress: Progress {
        Progress()
    }

    private var closure: (Data?, URLResponse?, Error?) -> Void
    private let mockResponse: MockDataResponse

    init(mockResponse: MockDataResponse, closure: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.mockResponse = mockResponse
        self.closure = closure
    }

    // We override the 'resume' method and simply call our closure
    // instead of actually resuming any task.
    override func resume() {
        closure(mockResponse.data, mockResponse.urlResponse, mockResponse.error)
    }

    override func cancel() {
        // nop
    }
}

class MockDataLoader: NSObject, URLDataLoader {
    var mockResponses = [MockDataResponse]()

    let testName: String

    init(testName: String) {
        self.testName = testName
    }

    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        guard let response = matchResponse(to: request) else {
            fatalError("\(testName): Missing response to URL: \(request.url!)")
        }

        return MockTask(mockResponse: response, closure: completionHandler)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let response = matchResponse(to: request) else {
            fatalError("\(testName): Missing response to URL: \(request.url!)")
        }

        if let error = response.error {
            throw error
        }

        guard let data = response.data else {
            fatalError("\(testName): Missing data to URL: \(request.url!))")
        }

        guard let urlResponse = response.urlResponse else {
            fatalError("\(testName): Missing urlResponse to URL: \(request.url!))")
        }

        return (data, urlResponse)
    }

    // MARK: - Response Mapping

    func matchResponse(to request: URLRequest) -> MockDataResponse? {
        for r in mockResponses where r.matcher(request) {
            return r
        }

        return nil
    }

    func mock(data: Data, matcher: @escaping MockDataLoaderMatcher) {
        let urlResponse = buildURLResponse(URL: URL(string: "https://mockdataloader.example.com")!, statusCode: 200)
        let mockResponse = MockDataResponse(data: data, urlResponse: urlResponse, error: nil, matcher: matcher)
        mock(response: mockResponse)
    }

    func mock(URLString: String, with data: Data) {
        mock(url: URL(string: URLString)!, with: data)
    }

    func mock(url: URL, with data: Data) {
        let urlResponse = buildURLResponse(URL: url, statusCode: 200)
        let mockResponse = MockDataResponse(data: data, urlResponse: urlResponse, error: nil) {
            let requestURL = $0.url!
            return requestURL.host == url.host && requestURL.path == url.path
        }
        mock(response: mockResponse)
    }

    func mock(response: MockDataResponse) {
        mockResponses.append(response)
    }

    func removeMappedResponses() {
        mockResponses.removeAll()
    }

    // MARK: - URL Response

    func buildURLResponse(URL: URL, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL,
            statusCode: statusCode,
            httpVersion: "2",
            headerFields: ["Content-Type": "application/json"]
        )!
    }

    // MARK: - Description

    override var debugDescription: String {
        var descriptionBuilder = DebugDescriptionBuilder(baseDescription: super.debugDescription)
        descriptionBuilder.add(key: "mockResponses", value: mockResponses)
        return descriptionBuilder.description
    }
}
