//
//  CXXNonOwningProxyArrayTests.m
//  CXXProxyKitTests
//
//  Created by Dmitry Khrykin on 14.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CXXProxyKit/CXXProxyKit.h>

#import "CXXExampleProxy.h"
#import "cxx_example_object.h"

@interface CXXNonOwningProxyArrayTests : XCTestCase

@end

@implementation CXXNonOwningProxyArrayTests

- (void)test_nonOwningArrayWithProxyClass {
    std::vector<cxx_example_object> vec = {cxx_example_object{1}, cxx_example_object{2}};
    __auto_type *proxyArray = cxx::make_non_owning_proxy_array(vec, CXXExampleProxy.class);

    XCTAssertEqual(proxyArray.count, vec.size());

    int index = 0;
    __weak CXXExampleProxy *weakProxyObj;

    @autoreleasepool {
        for (CXXExampleProxy *proxyObj in proxyArray) {
            weakProxyObj = proxyObj;
            XCTAssertEqual(vec[index++].value, proxyObj.value);
        }
    }

    // Check that we've iterated the whole array
    XCTAssertEqual(index, vec.size());

    // Check that element proxy object was deallocated.
    XCTAssertNil(weakProxyObj);
}

- (void)test_nonOwningArrayWithCustomAllocator {
    std::vector<cxx_example_object> vec = {cxx_example_object{1}, cxx_example_object{2}};

    CXXNonOwningProxyArray *proxyArray = cxx::make_non_owning_proxy_array(vec, [](const cxx_example_object &obj) {
        return [[CXXExampleProxy alloc] initWithUnownedPtr:&obj];
    });

    XCTAssertEqual(proxyArray.count, vec.size());

    __weak id weakObj;
    int index = 0;

    @autoreleasepool {
        for (CXXExampleProxy *obj in proxyArray) {
            weakObj = obj;
            XCTAssertEqual(vec[index++].value, obj.value);
        }
    }

    // Check that we've iterated the whole array
    XCTAssertEqual(index, vec.size());

    // Check that element's proxy object was deallocated.
    XCTAssertNil(weakObj);
}

@end
