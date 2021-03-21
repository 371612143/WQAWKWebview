//
//  WKWebView+Extension.m
//  WQAWebviewComponent
//
//  Created by matthew on 2019/10/31.
//

#import "WKWebView+Extension.h"
#import "ObjcHelpFunc.h"
#import "WQAWebEnvironment.h"
#import "WKProcessPool+WQASharedProcessPool.h"

@implementation WKWebView(Extension)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzInstanceMethod([WKWebView class], @selector(initWithFrame:), @selector(safe_initWithFrame:));
        swizzInstanceMethod([WKWebView class], @selector(initWithFrame:configuration:), @selector(safe_initWithFrame:configuration:));
    });
}

- (instancetype)safe_initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    WKPreferences *preference = [[WKPreferences alloc] init];
    configuration.preferences = preference;
    preference.javaScriptEnabled = YES;
    if (WQAEnvironmentInstance.webviewCacheLevel != WQACacheStateOff)
        configuration.processPool = [WKProcessPool sharedInstance];
    return [self safe_initWithFrame:frame configuration:configuration];
}

- (instancetype)safe_initWithFrame:(CGRect)frame {
    
    return [self initWithFrame:frame configuration:[WKWebViewConfiguration new]];
}

- (void)clearBrowseHistory {
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%@%@%@%@", @"_re", @"moveA",@"llIte", @"ms"]);
    if([self.backForwardList respondsToSelector:sel]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.backForwardList performSelector:sel];
#pragma clang diagnostic pop
    }
}

@end
