#  CXXProxyKit [![Test](https://github.com/khrykin/CXXProxyKit/workflows/Tests/badge.svg)](https://github.com/khrykin/CXXProxyKit/actions?query=workflow%3ATests)

Objective-C++ framework that helps to create Swift-friendly Objective-C wrappers of C++ interfaces.

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

@property (nonatomic, readonly) NSInteger value;

- (instancetype)initWithValue:(NSInteger)value;

@end


/*
    This class represents the non-const part of C++ interface. 
    It MUST be derived from its non-mutable counterpart. 
*/

@interface MutableExampleProxy : ExampleProxy <CXXMutableProxyObject>

@property (nonatomic) NSInteger value;

@end


/*
    Here CXX_PROXY_OBJECT macro defines an 'obj' instance variable 
    that is a pointer to 'const cxx_example_object'.
*/

@implementation CXX_PROXY_OBJECT(ExampleProxy, cxx_example_object, obj)

- (instancetype)initWithValue:(NSInteger)value {
    // We call 'initWithOwnedPtr:' initialzer to attach C++ object and take ownership of it.
    // Otherwise, if we don't want to take ownership, 'initWithUnownedPtr:' must be called.
    
    return [self initWithOwnedPtr:new cxx_example_object{static_cast<int>(value)}];
}

- (void)implementationDidLoad {
    // This method is called after the initialization is done.
    // You can use it to do any additional setup, such as setting up a delegate.
}

- (NSInteger)value {
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

- (void)setValue:(NSInteger)value {
    // Here we CAN call a non-const-quialified method:
    obj->set_value(static_cast<int>(value));
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

Note, that casts to Objective-C types create non-owning proxies, so you have to make sure that the backing C++ object will not be destroyed while any of its proxies are still alive.

## Making lightweight proxies for C++ containers 

You can create proxies for any C++ container at runtime with `cxx::make_non_owning_proxy_array`. 
The only requirement is that the container should have `begin()` and `end()` iterators, and its element's Objective-C proxy class must be defined:

```Objective-C++

#import <CXXProxyKit/CXXProxyKit.h>
#import <vector>

std::vector<cxx_example_object> objects;

CXXNonOwningProxyArray<ExampleProxy> *objectsProxies = cxx::make_non_owning_proxy_array(objects, ExampleProxy.class);

for (ExampleProxy *proxy: objectsProxies) {
    // Use proxy ...
}

```

## Using strongly typed collections in Swift

Swift and Objective-C generic user types don't play very well together, so, unfortunately, if you want to be able to iterate through a proxy array in Swift using `for ... in` syntax, you have to do a bit of work and define its backing class explicitly using `CXXArrayBackedProxyObject` protocol:

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
You can use this interface as a basis for the wrapper of your custom C++ container interface, as it also conforms to `CXXProxyObject`.

Then in Swift, you have to conform this class to `CXXProxyArraySequence`:

```Swift

import CXXProxyKit

extension ArrayOfProxies: CXXProxyArraySequence {
    public typealias Element = ExampleProxy
}

```
After this, you'll be able to iterate through it and call a subscript operator:

```Swift

let arrayProxy = ArrayOfProxies()

for (proxy in arrayProxy) {
    // proxy here is of type 'ExampleProxy'
}

let proxy = arrayProxy[2]

```

Alternatively, you can call `toArray()` on the instance of `CXXNonOwningProxyArray` and cast the element to a proxy type:
```Swift

for element in objectsProxies.toArray() {
    let proxy = element as! ExampleProxy
}

```
