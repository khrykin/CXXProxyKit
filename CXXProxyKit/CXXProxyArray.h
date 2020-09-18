//
//  CXXNonOwningProxyArray.h
//  CXXProxyKit
//
//  Created by Dmitry Khrykin on 01.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CXXProxyKit/CXXProxyObject.h>

NS_ASSUME_NONNULL_BEGIN

typedef id _Nonnull (^CXXArrayElementProxyAllocator)(size_t index);
typedef NSUInteger (^CXXArraySizeGetter)(void);

@protocol CXXProxyArray <NSFastEnumeration>

@property (nonatomic, readonly) NSInteger count;

- (id)objectAtIndexedSubscript:(NSInteger)idx;

@end

@protocol CXXArrayBackedProxyObject <CXXProxyArray, CXXProxyObject>

@end

@interface CXXNonOwningProxyArray<T> : NSObject <CXXProxyArray>

- (instancetype)initWithItemProxyAllocator:(CXXArrayElementProxyAllocator)itemProxyAllocator
                             countingBlock:(CXXArraySizeGetter)countingBlock;

- (T)objectAtIndexedSubscript:(NSInteger)idx;
- (NSArray<T> *)toArray;

@end

#define CXX_PROXY_ARRAY_OF(ObjcElementType)                                             \
                                                                                        \
- (ObjcElementType *)objectAtIndexedSubscript:(NSInteger)idx;

#define CXX_ARRAY_BACKED_PROXY_OBJECT(ObjcType, ObjcElementType, CppType, IvarName)     \
ObjcType (CXXDummyCategory) @end                                                        \
                                                                                        \
@interface ObjcType () {                                                                \
    cxx::proxy_ptr<const CppType> IvarName;                                             \
    CXXNonOwningProxyArray *proxyArray;                                                 \
}                                                                                       \
                                                                                        \
@end                                                                                    \
                                                                                        \
@implementation ObjcType                                                                \
                                                                                        \
- (instancetype)initWithOwnedPtr:(const void *)ptr {                                    \
    if (self = [super init]) {                                                          \
        IvarName = cxx::make_proxy_ptr<CppType>(ptr, cxx::owning);                      \
        proxyArray = cxx::make_non_owning_proxy_array(*IvarName, ObjcElementType.class);\
        if ([self respondsToSelector:@selector(implementationDidLoad)]) {               \
            [self implementationDidLoad];                                               \
        }                                                                               \
    }                                                                                   \
                                                                                        \
    return self;                                                                        \
}                                                                                       \
                                                                                        \
- (instancetype)initWithUnownedPtr:(const void *)ptr {                                  \
    if (self = [super init]) {                                                          \
        IvarName = cxx::make_proxy_ptr<CppType>(ptr, cxx::non_owning);                  \
        proxyArray = cxx::make_non_owning_proxy_array(*IvarName, ObjcElementType.class);\
        if ([self respondsToSelector:@selector(implementationDidLoad)]) {               \
            [self implementationDidLoad];                                               \
        }                                                                               \
    }                                                                                   \
                                                                                        \
    return self;                                                                        \
}                                                                                       \
                                                                                        \
- (const void *)implementationPtr {                                                     \
    return IvarName.get();                                                              \
}                                                                                       \
                                                                                        \
+ (NSUInteger)implementationSize {                                                      \
    return sizeof(CppType);                                                             \
}                                                                                       \
                                                                                        \
- (ObjcElementType *)objectAtIndexedSubscript:(NSInteger)idx {                          \
    return proxyArray[idx];                                                             \
}                                                                                       \
                                                                                        \
- (NSInteger)count {                                                                    \
    return proxyArray.count;                                                            \
}                                                                                       \
                                                                                        \
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state               \
                                  objects:(__unsafe_unretained id *)buffer              \
                                    count:(NSUInteger)bufferSize {                      \
      return [proxyArray countByEnumeratingWithState:state                              \
                                             objects:buffer                             \
                                               count:bufferSize];                       \
}                                                                                       \
                                                                                        \
- (NSArray *)toArray {                                                                  \
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:self.count];       \
        for (NSInteger idx = 0; idx < self.count; idx++) {                              \
            [array addObject:[self objectAtIndexedSubscript:idx]];                      \
        }                                                                               \
                                                                                        \
    return array;                                                                       \
}
                                                                                        

NS_ASSUME_NONNULL_END

#ifdef __cplusplus

#ifndef CXX_NON_OWNING_PROXY_ARRAY_H
#define CXX_NON_OWNING_PROXY_ARRAY_H

#include <vector>
#include <type_traits>

NS_ASSUME_NONNULL_BEGIN

namespace cxx {

/**
 Creates an instance of CXXNonOwningProxyArray from a generic C++ container using elementAllocator for creating proxy object.
 */
template <
    typename ContainerT,
    typename ElementAllocatorT,
    typename ElementT = typename std::iterator_traits<typename ContainerT::const_iterator>::value_type,
    std::enable_if_t<std::is_invocable<ElementAllocatorT, ElementT>::value, int> = 0
>
auto make_non_owning_proxy_array(ContainerT container,
                                 ElementAllocatorT elementAllocator) -> CXXNonOwningProxyArray * {
    auto itemProxyAllocator = ^(size_t index) {
        const ElementT &element = *(container.begin() + index);
        return elementAllocator(element);
    };

    return [[CXXNonOwningProxyArray alloc] initWithItemProxyAllocator:itemProxyAllocator
                                                        countingBlock:^size_t {
        return container.end() - container.begin();
    }];
}

/**
 Creates an instance of CXXNonOwningProxyArray from a generic C++ container using ItemProxyClass for creating proxy object.
 */
template <typename ContainerT>
auto make_non_owning_proxy_array(ContainerT container,
                                 Class<CXXProxyObject> ItemProxyClass) -> CXXNonOwningProxyArray * {
    return make_non_owning_proxy_array(container, [=] (const auto &element) {
        return [[(Class)ItemProxyClass alloc] initWithUnownedPtr:&element];
    });
}

}

NS_ASSUME_NONNULL_END

#endif

#endif


