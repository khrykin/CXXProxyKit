#  CXXProxyKit

Objective-C Framework that helps to create Swift-friendly wrappers of C++ interfaces.

## Example of Usage

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
    This class represents the const part of C++ interface 
*/

@interface ExampleProxy : NSObject <CXXProxyObject>

@property (nonatomic, readonly) int value;

- (instancetype)initWithValue:(int)value;

@end


/*
    This class represents the non-const part of C++ interface. 
    It MUST be derived from the class above. 
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
    // You can use it do any additional setup, such as setting up some delegate or whatever.
}

- (int)value {
    // Note that we can only call non-const qualified methods of a C++ object.
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
    // Here we can call a const-quialified method:
    obj->set_value(value);
}

@end


```

We can cast between C++ object and its Objective-C wrapper:

```Objective-C++

#import <CXXProxyKit/CXXProxyKit.h>

auto cxx_obj = cxx_example_object{};

ExampleProxy *proxy = cxx::proxy_cast<ExampleProxy>(cxx_obj);
MutableExampleProxy *mutableProxy = cxx::mutable_proxy_cast<ExampleProxy>(cxx_obj);

const auto &cxx_obj_ref = cxx::proxy_cast<cxx_example_object>(proxy);
auto &mutable_cxx_obj_ref = cxx::mutable_proxy_cast<cxx_example_object>(proxy);

```

Making lightweight proxies for containers: 

```Objective-C++

#import <CXXProxyKit/CXXProxyKit.h>
#import <vector>

std::vector<cxx_example_object> objects;

CXXNonOwningProxyArray<CXXExampleProxy> *objectsProxies = cxx::make_non_owning_proxy_array(objects, CXXExampleProxy.class);

for (CXXExampleProxy *proxy: objectsProxies) {
    // Use proxy ...
}

```
