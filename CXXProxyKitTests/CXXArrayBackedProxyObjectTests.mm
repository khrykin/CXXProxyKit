//
//  CXXArrayBackedProxyObjectTests.m
//  CXXProxyKitTests
//
//  Created by Dmitry Khrykin on 18.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CXXProxyKit/CXXProxyKit.h>

#import "CXXArrayOfProxies.h"
#import "CXXExampleProxy.h"
#import "cxx_example_object.h"


@interface CXXArrayBackedProxyObjectTests : XCTestCase {
    std::vector<cxx_example_object> objs;
    CXXArraryOfProxies *proxyArray;
}

@end

@implementation CXXArrayBackedProxyObjectTests

- (void)setUp {
    objs = {
        cxx_example_object{1},
        cxx_example_object{2}
    };

    proxyArray = cxx::proxy_cast<CXXArraryOfProxies>(objs);
}

- (void)test_iteration {
    int index = 0;
    for (CXXExampleProxy *proxy in proxyArray) {
        XCTAssertEqual(proxy.value, objs[index++].value);
    }

    XCTAssertEqual(index, objs.size());
}

- (void)test_subscriptAccess {
    XCTAssertEqual(proxyArray[0].value, objs[0].value);
}

- (void)test_count {
    XCTAssertEqual(proxyArray.count, objs.size());
}

@end
