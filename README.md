#  CXXProxyKit

Objective-C framework that helps to create Swift-friendly Objective-C wrappers of C++ interfaces.

## Creating an Objective-C wrapper of C++ interface

Here is the C++ interface that we want to wrap:

```C++

class cxx_example_object {
public:
    explicit cxx_example_object(int value);

    void set_value(int v);
    int get_value() const;

private:
    int value = 0;
};

```

And here is how we do it:

```Objective-C++

#import <CXXProxyKit/CXXProxyKit.h>

/* 
    This class represents the const part of C++ interface:
*/

@interface ExampleProxy : NSObject <CXXProxyObject>

@property (nonatomic, readonly) int value;

- (instancetype)initWithValue:(int)value;

@end


/*
    This class represents the non-const part of C++ interface. 
    It MUST be derived from it's non-mutable counterpart. 
*/

@interface MutableExampleProxy : ExampleProxy <CXXMutableProxyObject>

@property (nonatomic) int value;

@end


/*
    Here CXX_PROXY_OBJECT macro defines an 'obj' instance variable 
    that is a pointer to 'const cxx_example_object'.
*/

@implementation CXX_PROXY_OBJECT(ExampleProxy, cxx_example_object, obj)

- (instancetype)initWithValue:(int)value {
    // We call 'initWithOwnedPtr:' initialzer to attach C++ object and take ownership of it.
    // Otherwise, if we don't want to take ownership, 'initWithUnownedPtr:' must be called.
    
    return [self initWithOwnedPtr:new cxx_example_object{value}];
}

- (void)implementationDidLoad {
    // This method is called after the initialization is done.
    // You can use it do any additional setup, such as setting up a delegate.
}

- (int)value {
    // Note that we can only call const qualified methods of a C++ object whithin the implementation of this class.
    return obj->get_value();
}

@end


/*
    CXX_MUTABLE_PROXY_OBJECT macro defines an 'obj' instance variable 
    that is a non-const pointer to 'cxx_example_object'.
*/

@implementation CXX_MUTABLE_PROXY_OBJECT(MutableExampleProxy, cxx_example_object, obj)

// Use getter from parent class
@dynamic value;

- (void)setValue:(int)value {
    // Here we CAN call a non-const-quialified method:
    obj->set_value(value);
}

@end


```

## Casting

We can cast between C++ object and its Objective-C wrapper:

```Objective-C++

#import <CXXProxyKit/CXXProxyKit.h>

auto cxx_obj = cxx_example_object{};

ExampleProxy *proxy = cxx::proxy_cast<ExampleProxy>(cxx_obj);
MutableExampleProxy *mutableProxy = cxx::mutable_proxy_cast<ExampleProxy>(cxx_obj);

const auto &cxx_obj_ref = cxx::proxy_cast<cxx_example_object>(proxy);
auto &mutable_cxx_obj_ref = cxx::mutable_proxy_cast<cxx_example_object>(mutableProxy);

```

Note, that casts to Objective-C types create non-owning proxies, so you have to make sure that backing C++ objects will not be destroyed while any of it's proxies are still alive.

## Making Lightweight Proxies for C++ Containers: 

```Objective-C++

#import <CXXProxyKit/CXXProxyKit.h>
#import <vector>

std::vector<cxx_example_object> objects;

CXXNonOwningProxyArray<CXXExampleProxy> *objectsProxies = cxx::make_non_owning_proxy_array(objects, CXXExampleProxy.class);

for (CXXExampleProxy *proxy: objectsProxies) {
    // Use proxy ...
}

```

## Using Strongly Typed Collections in Swift

Swift and Objective-C generic user types don't play very well together, so if you want to be able to iterate through a proxy array in Swift using `for ... in` syntax, you have to define it's backing class explicitly like that:

```Objective-C++

#import <CXXProxyKit/CXXProxyKit.h>

@interface ArraryOfProxies : NSObject <CXXArrayBackedProxyObject> CXX_PROXY_ARRAY_OF(ExampleProxy)

@end

@implementation CXX_ARRAY_BACKED_PROXY_OBJECT(ArraryOfProxies,
                                              ExampleProxy,
                                              std::vector<cxx_example_object>,
                                              objects)

@end

```
Then in Swift you have to conform it to `Sequence`:

```Swift

import CXXProxyKit

extension ArraryOfProxies: CXXProxyListSequence {
    public typealias Element = CXXExampleProxy
}

```
