//
//  CXXArrayOfProxies.h
//  CXXProxyKitTests
//
//  Created by Dmitry Khrykin on 18.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXXExampleProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface CXXArraryOfProxies : NSObject <CXXArrayBackedProxyObject> CXX_PROXY_ARRAY_OF(CXXExampleProxy)

@end

#ifdef __cplusplus
extern "C" {
#endif

CXXArraryOfProxies *CXXArraryOfProxiesMakeForTesting(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
