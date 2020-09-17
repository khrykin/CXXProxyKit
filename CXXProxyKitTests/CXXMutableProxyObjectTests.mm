//
//  CXXMutableProxyObjectTests.m
//  CXXProxyKitTests
//
//  Created by Dmitry Khrykin on 16.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <CXXProxyKit/CXXProxyKit.h>

#import "CXXExampleProxy.h"
#import "cxx_example_object.h"

@interface CXXMutableProxyObjectTests : XCTestCase {
    bool cxx_obj_deleted;
    std::function<void(void)> on_cxx_obj_deleted;
}

@end

@implementation CXXMutableProxyObjectTests

- (void)setUp {
    cxx_obj_deleted = false;
    on_cxx_obj_deleted = [self] { cxx_obj_deleted = true; };
}

- (void)test_initializesWithMutableUnownedPtr {
    auto cxx_obj = cxx_example_object{4, on_cxx_obj_deleted};

    __weak CXXMutableExampleProxy *weakProxy;

    {
        CXXMutableExampleProxy *proxy = [[CXXMutableExampleProxy alloc] initWithUnownedPtr:&cxx_obj];
        weakProxy = proxy;

        XCTAssertEqual(proxy.value, cxx_obj.value);
    }

    XCTAssertNil(weakProxy);
    XCTAssertEqual(cxx_obj.value, 4);
    XCTAssertFalse(cxx_obj_deleted);
}

- (void)test_initializesWithMutableOwnedPtr {
    auto *cxx_obj_ptr = new cxx_example_object{4, on_cxx_obj_deleted};

    __weak CXXMutableExampleProxy *weakProxy;

    {
        CXXMutableExampleProxy *proxy = [[CXXMutableExampleProxy alloc] initWithOwnedPtr:cxx_obj_ptr];
        weakProxy = proxy;

        XCTAssertEqual(proxy.value, cxx_obj_ptr->value);
    }

    XCTAssertNil(weakProxy);
    XCTAssertTrue(cxx_obj_deleted);
}

- (void)test_initializesOwningMutableProxyWithCustomInitializer {
    __weak CXXMutableExampleProxy *weakProxy;

    {
        CXXMutableExampleProxy *proxy = [[CXXMutableExampleProxy alloc] initWithValue:4];
        weakProxy = proxy;

        auto &cxx_obj = cxx::mutable_proxy_cast<cxx_example_object>(proxy);
        cxx_obj.on_destruction = on_cxx_obj_deleted;

        XCTAssertEqual(cxx_obj.value, 4);
        XCTAssertEqual(proxy.value, cxx_obj.value);
    }

    XCTAssertNil(weakProxy);
    XCTAssertTrue(cxx_obj_deleted);
}

-(void)test_callsNonConstMethodOfCXXObject {
    auto cxx_obj = cxx_example_object{};

    CXXMutableExampleProxy *proxy = [[CXXMutableExampleProxy alloc] initWithUnownedPtr:&cxx_obj];

    proxy.value = 12;

    XCTAssertEqual(proxy.value, 12);
    XCTAssertEqual(cxx_obj.value, 12);
}

- (void)test_castsToMutableProxyObject {
    auto cxx_obj = cxx_example_object{4};

    CXXMutableExampleProxy *proxy = cxx::mutable_proxy_cast<CXXMutableExampleProxy>(cxx_obj);

    XCTAssertEqual(proxy.value, 4);

    proxy.value = 6;

    XCTAssertEqual(cxx_obj.value, 6);
}

- (void)test_castsFromMutableProxyObject {
    CXXMutableExampleProxy *proxy = [[CXXMutableExampleProxy alloc] initWithValue:4];

    auto &cxx_object = cxx::mutable_proxy_cast<cxx_example_object>(proxy);

    XCTAssertEqual(cxx_object.value, 4);

    cxx_object.value = 6;

    XCTAssertEqual(proxy.value, 6);
}

@end
