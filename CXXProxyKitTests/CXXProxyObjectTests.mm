//
//  CXXProxyObjectTests.m
//  CXXProxyKitTests
//
//  Created by Dmitry Khrykin on 14.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <CXXProxyKit/CXXProxyKit.h>

#import "CXXExampleProxy.h"
#import "cxx_example_object.h"

@interface CXXProxyObjectTests : XCTestCase {
    bool cxx_obj_deleted;
    std::function<void(void)> on_cxx_obj_deleted;
}

@end

@implementation CXXProxyObjectTests

- (void)setUp {
    cxx_obj_deleted = false;
    on_cxx_obj_deleted = [self] { cxx_obj_deleted = true; };
}

- (void)test_initializesWithUnownedPtr {
    auto cxx_obj = cxx_example_object{4, on_cxx_obj_deleted};

    __weak CXXExampleProxy *weakProxy;

    {
        CXXExampleProxy *proxy = [[CXXExampleProxy alloc] initWithUnownedPtr:&cxx_obj];
        weakProxy = proxy;

        XCTAssertEqual(proxy.value, cxx_obj.value);
    }

    XCTAssertNil(weakProxy);
    XCTAssertEqual(cxx_obj.value, 4);
    XCTAssertFalse(cxx_obj_deleted);
}

- (void)test_initializesWithOwnedPtr {
    auto *cxx_obj_ptr = new cxx_example_object{4, on_cxx_obj_deleted};

    __weak CXXExampleProxy *weakProxy;

    {
        CXXExampleProxy *proxy = [[CXXExampleProxy alloc] initWithOwnedPtr:cxx_obj_ptr];
        weakProxy = proxy;

        XCTAssertEqual(proxy.value, cxx_obj_ptr->value);
    }

    XCTAssertNil(weakProxy);
    XCTAssertTrue(cxx_obj_deleted);
}

- (void)test_initializesOwningProxyWithCustomInitializer {
    __weak CXXExampleProxy *weakProxy;

    {
        CXXExampleProxy *proxy = [[CXXExampleProxy alloc] initWithValue:4];
        weakProxy = proxy;

        const auto &cxx_obj = cxx::proxy_cast<cxx_example_object>(proxy);
        cxx_obj.on_destruction = on_cxx_obj_deleted;

        XCTAssertEqual(cxx_obj.value, 4);
        XCTAssertEqual(proxy.value, cxx_obj.value);
    }

    XCTAssertNil(weakProxy);
    XCTAssertTrue(cxx_obj_deleted);
}

- (void)test_callsImplementationDidLoad {
    __block BOOL implementationDidLoad = NO;

    __auto_type callback = ^{
        implementationDidLoad = YES;
    };

    auto cxx_obj = cxx_example_object{};

    (void)[[CXXExampleProxy alloc] initWithUnownedPtr:&cxx_obj
                                     delegateCallback:callback];

    XCTAssertTrue(implementationDidLoad);

    implementationDidLoad = NO;


    (void)[[CXXExampleProxy alloc] initWithOwnedPtr:new cxx_example_object{}
                                   delegateCallback:callback];

    XCTAssertTrue(implementationDidLoad);
}

- (void)test_castsToProxyObject {
    auto cxx_obj = cxx_example_object{4};

    CXXExampleProxy *proxy = cxx::proxy_cast<CXXExampleProxy>(cxx_obj);

    XCTAssertEqual(proxy.value, 4);
}

- (void)test_castsFromProxyObject {
    CXXExampleProxy *proxy = [[CXXExampleProxy alloc] initWithValue:4];

    auto &cxx_object = cxx::proxy_cast<cxx_example_object>(proxy);

    XCTAssertEqual(cxx_object.value, 4);
}


@end
