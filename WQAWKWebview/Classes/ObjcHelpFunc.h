//
//  ObjcHelpFunc.h
//  objc
//  Created by matthew on 2019/3/20.
//  Copyright © 2019年 matthew. All rights reserved.
//
#ifndef ObjcHelpFunc_h
#define ObjcHelpFunc_h
#import <objc/runtime.h>

#define INTERNAL_VERSION NO

#ifdef __cplusplus
extern "C" {
#endif
    void swizzClassMethod(Class cls, SEL orginSel, SEL newSel);
    void swizzInstanceMethod(Class cls, SEL orginSel, SEL newSel);
    void runOnMainThread(void(^block)(void));
    void runOnMainThreadAsync(void(^block)(void));
    void runOnMainthreadIdl(void(^block)(void));
    void logWebInfo(NSString *info);
    NSString *bgf_URLDecoding(NSString *origin);
#ifdef __cplusplus
}
#endif

#endif /* ObjcHelpFunc_h */
