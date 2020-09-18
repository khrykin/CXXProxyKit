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

    func test_iteration() throws {
       let proxies = CXXArraryOfProxiesMakeForTesting()
        var index = 0;
        for proxy in proxies {
            XCTAssertEqual(proxy.value, index)
            index += 1
        }

        XCTAssertEqual(index, 2)
    }

}
