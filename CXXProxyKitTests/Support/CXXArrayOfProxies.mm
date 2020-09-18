//
//  CXXArrayOfProxies.m
//  CXXProxyKitTests
//
//  Created by Dmitry Khrykin on 18.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import <vector>
#import "CXXArrayOfProxies.h"
#import "cxx_example_object.h"

@implementation CXX_ARRAY_BACKED_PROXY_OBJECT(CXXArraryOfProxies, CXXExampleProxy, std::vector<cxx_example_object>, objects)

@end

CXXArraryOfProxies *CXXArraryOfProxiesMakeForTesting(void) {
    std::vector<cxx_example_object> objs = {
        cxx_example_object{0},
        cxx_example_object{1}
    };

    return cxx::proxy_cast<CXXArraryOfProxies>(objs);
}
