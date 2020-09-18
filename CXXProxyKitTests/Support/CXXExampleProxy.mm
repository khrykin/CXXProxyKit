//
//  CXXProxy.m
//  CXXProxyKitTests
//
//  Created by Dmitry Khrykin on 14.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import "CXXExampleProxy.h"
#import "cxx_example_object.h"

@interface CXXExampleProxy ()

@property(nonatomic, strong) void (^callback)(void);

@end

@implementation CXX_PROXY_OBJECT(CXXExampleProxy, cxx_example_object, obj)

- (instancetype)initWithValue:(NSInteger)value {
    return [self initWithOwnedPtr:new cxx_example_object{static_cast<int>(value)}];
}

- (instancetype)initWithUnownedPtr:(const void *)ptr delegateCallback:(void (^)(void)) callback {
    self.callback = callback;
    return [self initWithUnownedPtr:ptr];
}

- (instancetype)initWithOwnedPtr:(const void *)ptr delegateCallback:(void (^)(void)) callback {
    self.callback = callback;
    return [self initWithOwnedPtr:ptr];
}

- (void)implementationDidLoad {
    if (self.callback) {
        self.callback();
    }
}

- (NSInteger)value {
    return obj->value;
}

@end


@implementation CXX_MUTABLE_PROXY_OBJECT(CXXMutableExampleProxy, cxx_example_object, obj)

@dynamic value;

- (void)setValue:(NSInteger)value {
    obj->value = static_cast<int>(value);
}

@end
