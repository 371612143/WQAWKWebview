//
//  WQASharedProcessPool.m
//  WQAWebviewComponent
//
//  Created by matthew on 2019/11/12.
//

#import "WKProcessPool+WQASharedProcessPool.h"

@implementation WKProcessPool(WQASharedProcessPool)

+ (instancetype)sharedInstance {
    static WKProcessPool *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WKProcessPool alloc] init];
    });
    return instance;
}
@end
