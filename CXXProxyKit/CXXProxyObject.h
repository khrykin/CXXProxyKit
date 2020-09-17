//
//  CXXProxyObject.h
//  CXXProxyKit
//
//  Created by Dmitry Khrykin on 14.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CXXProxyKit/CXXProxyPtr.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - CXXProxyObject

@protocol CXXProxyObject <NSObject>

/**
 The size of a backing C++ object.
 */
@property (nonatomic, class, readonly) NSUInteger implementationSize;

/**
 A pointer to a backing C++ object.
 */
@property (nonatomic, readonly) const void *implementationPtr;

/**
 Initializes a proxy object with a pointer to a backing C++ object, taking ownership of it.
 */
- (instancetype)initWithOwnedPtr:(const void *)ptr;

/**
 Initializes a proxy object with a pointer to a backing C++ object, whithout taking ownership of it.
 */
- (instancetype)initWithUnownedPtr:(const void *)ptr;

/**
 Checks if pointers to backing C++ objects are equal.
 */
- (BOOL)isEqualTo:(nullable id<CXXProxyObject>)otherObject;


@optional

/**
 This method is called after the backing C++ object is attached to an Objective-C proxy.

 Sublclasses of CXXProxyObject can override this method to implement custom setup logic (e.g. setting up a delegate).
 */
- (void)implementationDidLoad;

@end

#pragma mark - CXXMutableProxyObject

@protocol CXXMutableProxyObject <CXXProxyObject>

/**
 A mutalbe pointer to backing C++ object.
 */
@property (nonatomic, readonly) void *mutableImplementationPtr;

/**
 Initializes a proxy object with a mutable pointer to a backing C++ object, taking ownership of it.
 */
- (instancetype)initWithOwnedPtr:(void *)ptr;

/**
 Initializes a proxy object with a mutable pointer to a backing C++ object,
 whithout taking ownership of it.
 */
- (instancetype)initWithUnownedPtr:(void *)ptr;

@end

#pragma mark - Sublcasses Default Implementations Macros

/**
 This macro must be called after the @implementation keyword of a CXXProxyObject subclass.
 */

#define CXX_PROXY_OBJECT(ObjcType, CppType, IvarName)                       \
ObjcType (CXXDummyCategory) @end                                            \
                                                                            \
@interface ObjcType () {                                                    \
    cxx::proxy_ptr<const CppType> IvarName;                                 \
}                                                                           \
                                                                            \
@end                                                                        \
                                                                            \
@implementation ObjcType                                                    \
                                                                            \
- (instancetype)initWithOwnedPtr:(const void *)ptr {                        \
    if (self = [super init]) {                                              \
        IvarName = cxx::make_proxy_ptr<CppType>(ptr, cxx::owning);          \
        if ([self respondsToSelector:@selector(implementationDidLoad)]) {   \
            [self implementationDidLoad];                                   \
        }                                                                   \
    }                                                                       \
                                                                            \
    return self;                                                            \
}                                                                           \
                                                                            \
- (instancetype)initWithUnownedPtr:(const void *)ptr {                      \
    if (self = [super init]) {                                              \
        IvarName = cxx::make_proxy_ptr<CppType>(ptr, cxx::non_owning);      \
        if ([self respondsToSelector:@selector(implementationDidLoad)]) {   \
            [self implementationDidLoad];                                   \
        }                                                                   \
    }                                                                       \
                                                                            \
    return self;                                                            \
}                                                                           \
                                                                            \
- (const void *)implementationPtr {                                         \
    return IvarName.get();                                                  \
}                                                                           \
                                                                            \
+ (NSUInteger)implementationSize {                                          \
    return sizeof(CppType);                                                 \
}

/**
 This macro must be called after the @implementation keyword of a CXXMutableProxyObject subclass.
 */

#define CXX_MUTABLE_PROXY_OBJECT(ObjcType, CppType, IvarName)               \
ObjcType (CXXDummyCategory) @end                                            \
                                                                            \
@interface ObjcType () {                                                    \
    cxx::proxy_ptr<CppType> IvarName;                                       \
}                                                                           \
                                                                            \
@end                                                                        \
                                                                            \
@implementation ObjcType                                                    \
                                                                            \
- (instancetype)initWithOwnedPtr:(void *)ptr {                              \
    if (self = [super initWithUnownedPtr:ptr]) {                            \
        IvarName = cxx::make_proxy_ptr<CppType>(ptr, cxx::owning);          \
    }                                                                       \
                                                                            \
    return self;                                                            \
}                                                                           \
                                                                            \
- (instancetype)initWithUnownedPtr:(void *)ptr {                            \
    if (self = [super initWithUnownedPtr:ptr]) {                            \
        IvarName = cxx::make_proxy_ptr<CppType>(ptr, cxx::non_owning);      \
    }                                                                       \
                                                                            \
    return self;                                                            \
}                                                                           \
                                                                            \
- (void *)mutableImplementationPtr {                                        \
    return IvarName.get();                                                  \
}

NS_ASSUME_NONNULL_END

#pragma mark - Casting Between Ojective-C Proxy and Represented C++ Object

#ifdef __cplusplus

#ifndef CXX_PROXY_OBJECT_H
#define CXX_PROXY_OBJECT_H

#import <type_traits>

NS_ASSUME_NONNULL_BEGIN

namespace cxx {

template <typename T>
using cv_removed = typename std::remove_cv<T>::type;

template <typename T>
struct is_objc_ptr : std::integral_constant<bool,
    std::is_convertible_v<id, T> &&
    !std::is_null_pointer_v<T>
> {};

template <typename T>
constexpr const bool is_objc_ptr_v = is_objc_ptr<T>::value;


/**
 Creates a non-owning Objective-C proxy object.
 */
template <
    typename ObjCType,
    typename CppType,
    std::enable_if_t<is_objc_ptr_v<ObjCType *>, int> = 0
>
auto proxy_cast(const CppType &cpp_object) -> ObjCType * _Nonnull {
    static_assert(!std::is_pointer_v<CppType>, "CppType must not be a pointer");

    return [[ObjCType alloc] initWithUnownedPtr:&cpp_object];
}

/**
 Creates a mutable version of non-owning Objective-C proxy object.
 */
template <
    typename ObjCType,
    typename CppType,
    std::enable_if_t<is_objc_ptr_v<ObjCType *>, int> = 0
>
auto mutable_proxy_cast(CppType &cpp_object) -> ObjCType * _Nonnull {
    static_assert(!std::is_pointer_v<CppType>, "CppType must not be a pointer");

    return [[ObjCType alloc] initWithUnownedPtr:&cpp_object];
}

/**
 Returns a const reference to a backing cpp pbject.
 */
template <typename CppType, std::enable_if_t<!is_objc_ptr_v<CppType *>, int> = 0>
auto proxy_cast(id<CXXProxyObject> proxy) -> const cv_removed<CppType> & {
    return *static_cast<const cv_removed<CppType> *>(proxy.implementationPtr);
}

/**
 Returns a mutable reference to a backing cpp pbject.
 */
template <typename CppType, std::enable_if_t<!is_objc_ptr_v<CppType *>, int> = 0>
auto mutable_proxy_cast(id<CXXMutableProxyObject> proxy) -> cv_removed<CppType> & {
    return *static_cast<CppType *>(proxy.mutableImplementationPtr);
}

}

NS_ASSUME_NONNULL_END

#endif

#endif

