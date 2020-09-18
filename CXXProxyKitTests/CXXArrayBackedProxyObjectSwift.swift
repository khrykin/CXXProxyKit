//
//  CXXArrayBackedProxyObjectSwift.swift
//  CXXProxyKitTests
//
//  Created by Dmitry Khrykin on 18.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

import XCTest
import CXXProxyKit

extension CXXArraryOfProxies : CXXProxyArraySequence {
    public typealias Element = CXXExampleProxy
}

class CXXArrayBackedProxyObjectSwift: XCTestCase {
    var proxies: CXXArraryOfProxies!

    override func setUp() {
        proxies = CXXArraryOfProxiesMakeForTesting()
    }

    func test_iteration() throws {
        var index = 0;
        for proxy in proxies {
            XCTAssertEqual(proxy.value, index)
            index += 1
        }

        XCTAssertEqual(index, 2)
    }

    func test_subscriptAccess() throws {
        XCTAssertEqual(proxies[1].value, 1)
    }

}
