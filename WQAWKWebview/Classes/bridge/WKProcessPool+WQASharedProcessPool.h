//
//  WQASharedProcessPool.h
//  WQAWebviewComponent
//
//  Created by matthew on 2019/11/12.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "WQAWebCommonDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKProcessPool(WQASharedProcessPool)
+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
