//
//  CXXProxy.h
//  CXXProxyKitTests
//
//  Created by Dmitry Khrykin on 14.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import <CXXProxyKit/CXXProxyKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CXXExampleProxy : NSObject <CXXProxyObject>

@property (nonatomic, readonly) int value;

- (instancetype)initWithUnownedPtr:(const void *)ptr delegateCallback:(void (^)(void)) callback;
- (instancetype)initWithOwnedPtr:(const void *)ptr delegateCallback:(void (^)(void)) callback;

- (instancetype)initWithValue:(int)value;

@end

@interface CXXMutableExampleProxy : CXXExampleProxy <CXXMutableProxyObject>

@property (nonatomic) int value;

@end


NS_ASSUME_NONNULL_END
