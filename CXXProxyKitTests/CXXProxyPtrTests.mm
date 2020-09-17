//
//  CXXProxyPtrTests.m
//  CXXProxyKitTests
//
//  Created by Dmitry Khrykin on 15.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <CXXProxyKit/CXXProxyPtr.h>

#import "cxx_example_object.h"

@interface CXXProxyPtrTests : XCTestCase {
    bool cxx_obj_deleted;
    std::function<void(void)> on_cxx_obj_deleted;
}

@end

@implementation CXXProxyPtrTests

- (void)setUp {
    cxx_obj_deleted = false;
    on_cxx_obj_deleted = [self] { cxx_obj_deleted = true; };
}

- (void)test_proxyPtrNonOwning {
    auto stack_obj = cxx_example_object{4, on_cxx_obj_deleted};

    {
        auto non_owning_ptr1 = cxx::proxy_ptr(&stack_obj);
        auto non_owning_ptr2 = cxx::proxy_ptr(&stack_obj, cxx::non_owning);
    }

    XCTAssertFalse(cxx_obj_deleted);
}

- (void)test_proxyPtrOwning {
    cxx_example_object *allocd_obj = new cxx_example_object{4, on_cxx_obj_deleted};

    {
        auto owning_ptr = cxx::proxy_ptr(allocd_obj, cxx::owning);
    }

    XCTAssertTrue(cxx_obj_deleted);
}

- (void)test_proxyPtrDefaultInitialization {
    auto empty_ptr = cxx::proxy_ptr<cxx_example_object>{};

    XCTAssert(empty_ptr == nullptr);
}

- (void)test_proxyPtrRawPtrAccess {
    auto obj = cxx_example_object{4};
    auto non_owning_ptr = cxx::proxy_ptr(&obj);

    XCTAssertEqual(non_owning_ptr.get(), &obj);
}

- (void)test_proxyPtrIndirectionOperator {
    auto obj = cxx_example_object{4};
    auto non_owning_ptr = cxx::proxy_ptr(&obj);

    XCTAssertEqual((*non_owning_ptr).value, 4);
    XCTAssertEqual(non_owning_ptr->value, 4);
}

- (void)test_proxyPtrBoolOperator {
    auto obj = cxx_example_object{4};
    auto non_owning_ptr = cxx::proxy_ptr(&obj);
    auto empty_ptr = cxx::proxy_ptr<cxx_example_object>{};

    XCTAssertTrue(non_owning_ptr);
    XCTAssertFalse(empty_ptr);
}

- (void)test_proxyPtrEqualityOperators {
    auto obj1 = cxx_example_object{4};
    auto obj2 = cxx_example_object{4};
    auto *allocd_obj = new cxx_example_object{4};

    auto non_owning_ptr1 = cxx::proxy_ptr(&obj1);
    auto non_owning_ptr2 = cxx::proxy_ptr(&obj2);

    XCTAssert(cxx::proxy_ptr(allocd_obj, cxx::owning) == allocd_obj);
    XCTAssert(non_owning_ptr1 == cxx::proxy_ptr(&obj1));
    XCTAssert(non_owning_ptr1 != non_owning_ptr2);
}

- (void)test_proxyPtrEnforcesConst {
    const auto *allocd_obj = new cxx_example_object{4};

    auto owning_ptr = cxx::proxy_ptr(allocd_obj, cxx::owning);

    // This mustn't compile:
    // owning_ptr->value = 10;

    XCTAssertEqual(owning_ptr->get_value(), 4);
}

- (void)test_proxyPtrCopyAssigmentFromRawPtr {
    auto *allocd_obj1 = new cxx_example_object{4, on_cxx_obj_deleted};

    {
        auto owning_ptr = cxx::proxy_ptr(allocd_obj1, cxx::owning);

        auto *allocd_obj2 = new cxx_example_object{4, on_cxx_obj_deleted};
        owning_ptr = allocd_obj2;

        XCTAssertEqual(owning_ptr.get(), allocd_obj2);

        // allocd_obj1 is deleted.
        XCTAssertTrue(cxx_obj_deleted);

        cxx_obj_deleted = false;
    }

    // allocd_obj2 is deleted.
    XCTAssertTrue(cxx_obj_deleted);
}

- (void)test_proxyPtrMoveAssigment {
    auto *allocd_obj = new cxx_example_object{4};
    auto prev_owning_ptr = cxx::proxy_ptr(allocd_obj, cxx::owning);
    auto was_non_owning_ptr = cxx::proxy_ptr<cxx_example_object>();

    // Transfer ownership to the new pointer, make sure that it's become owning:
    was_non_owning_ptr = std::move(prev_owning_ptr);

    XCTAssert(prev_owning_ptr == nullptr);
    XCTAssertTrue(was_non_owning_ptr.is_owning);
    XCTAssertEqual(was_non_owning_ptr.get(), allocd_obj);
}

- (void)test_proxyPtrMoveConstructor {
    auto *allocd_obj = new cxx_example_object{4};
    auto prev_owning_ptr = cxx::proxy_ptr(allocd_obj, cxx::owning);

    // Transfer ownership to the new pointer, make sure that it's become owning:
    cxx::proxy_ptr<cxx_example_object> new_ptr = std::move(prev_owning_ptr);

    XCTAssert(prev_owning_ptr == nullptr);
    XCTAssertTrue(new_ptr.is_owning);
    XCTAssertEqual(new_ptr.get(), allocd_obj);
}

- (void)test_proxyPtrFromVoidPtr {
    auto *allocd_obj = static_cast<void *>(new cxx_example_object{4});
    auto prev_owning_ptr = cxx::make_proxy_ptr<cxx_example_object>(allocd_obj, cxx::owning);

    XCTAssertEqual(prev_owning_ptr->value, 4);
}

@end
