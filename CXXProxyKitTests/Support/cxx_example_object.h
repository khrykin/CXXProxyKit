//
//  cxx_object.h
//  CXXProxyKit
//
//  Created by Dmitry Khrykin on 14.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#ifndef cxx_object_h
#define cxx_object_h

#include <functional>

struct cxx_example_object {
    int value = 0;

    mutable std::function<void()> on_destruction;

    ~cxx_example_object() {
        if (on_destruction)
            on_destruction();
    }

    int get_value() const {
        return value;
    }
};

#endif /* cxx_object_h */
