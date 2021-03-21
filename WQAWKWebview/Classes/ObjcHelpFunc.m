//
//  ObjcHelpFunc.c
//  debug-objc
//
//  Created by matthew on 2019/3/20.
//  Copyright © 2019年 matthew. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<WQALog/WQALog.h>)
#import <WQALog/WQALog.h>
#endif
#include "ObjcHelpFunc.h"
#import "WQAWebCommonDefine.h"


void swizzClassMethod(Class cls, SEL orginSel, SEL newSel) {
    Class metaCls = object_getClass(cls);
    Method orginMethod = class_getInstanceMethod(metaCls, orginSel);
    Method newinMethod = class_getInstanceMethod(metaCls, newSel);
    if (class_addMethod(metaCls, orginSel, method_getImplementation(newinMethod), method_getTypeEncoding(newinMethod))) {
        class_replaceMethod(metaCls, newSel, method_getImplementation(orginMethod), method_getTypeEncoding(orginMethod));
    }
    else {
        method_exchangeImplementations(orginMethod, newinMethod);
    }
}

void swizzInstanceMethod(Class cls, SEL orginSel, SEL newSel) {
    Method orginMethod = class_getInstanceMethod(cls, orginSel);
    Method newinMethod = class_getInstanceMethod(cls, newSel);
    if (class_addMethod(cls, orginSel, method_getImplementation(newinMethod), method_getTypeEncoding(newinMethod))) {
        class_replaceMethod(cls, newSel, method_getImplementation(orginMethod), method_getTypeEncoding(orginMethod));
    }
    else {
        method_exchangeImplementations(orginMethod, newinMethod);
    }
}


void runOnMainThread(void(^block)(void)) {
    if (unlikely(!block)) {
        return;
    }
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

void runOnMainThreadAsync(void(^block)(void)) {
    if (unlikely(!block)) {
        return;
    }
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}
 
void runOnMainthreadIdl(void(^block)(void)) {
    if (unlikely(!block)) {
        return;
    }
    __block CFRunLoopObserverRef rlo = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopBeforeWaiting | kCFRunLoopExit, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        block();
        CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), rlo, kCFRunLoopDefaultMode);
    });
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), rlo, kCFRunLoopDefaultMode);
}

void logWebInfo(NSString *info) {
    if (info.length == 0)
        return;
#if __has_include(<WQALog/WQALog.h>)
    [Log i:@"WQAWkWebviewSDK" format:@"%@", info];
#else
    NSLog(@"WQAWkWebviewSDK info:%@", info);
#endif
}

NSString *bgf_URLDecoding(NSString *origin) {
    NSMutableString *string = [NSMutableString stringWithString:origin];
    [string replaceOccurrencesOfString:@"+"
                            withString:@" "
                               options:NSLiteralSearch
                                 range:NSMakeRange(0, [string length])];
    return [string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
