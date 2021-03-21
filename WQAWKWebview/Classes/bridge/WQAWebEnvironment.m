//
//  WQAWebEnvironment.m
//  WQAWebview
//
//  Created by matthew on 2019/3/26.
//  Copyright © 2019年 matthew. All rights reserved.
//

#import "WQAWebEnvironment.h"
#import <WebKit/WebKit.h>
#import "WQAWkWebview.h"
#import <WQAWebviewPool.h>
#import "ObjcHelpFunc.h"
#if __has_include(<WQAOfflineUtil.h>)
#import "WQAOfflineUtil.h"
#import "WQAJavaScriptStrResource.h"
#endif

@interface WQAWebEnvironment()
@property (nonatomic, strong)WKUserScript *ajaxHookScript;
@property (nonatomic, strong)WKUserScript *jsBridgeScript;
@property (nonatomic, strong)NSMutableDictionary *HTTPPostBodyDict;
@property (nonatomic, strong)WQAWebviewPool *webviewPools;
@property (nonatomic, strong)NSMutableArray *cacheBlackList; //禁用缓存的黑名单
@property (nonatomic, strong)dispatch_queue_t postBodyQueue;
@end

@implementation WQAWebEnvironment

SINGLETON_IMP(WQAWebEnvironment)

- (instancetype)init {
    if (self = [super init]) {
        _staticResourceList = @[@"js", @"css", @"html", @"png", @"jpg", @"webp", @"gif", @"mp4", @"ico", @"svg", @"json"];
        _cacheBlackList = [NSMutableArray new];
        _HTTPPostBodyDict = [NSMutableDictionary new];
        _postBodyQueue = dispatch_queue_create("WQAwebview_postbody_queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {

}

- (void)addUrlsToBlackList:(NSArray<NSString *> *)urls {
    for (NSString *item in urls) {
        if (![item isKindOfClass:[NSString class]] || item.length == 0)
            continue;
        NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:item] resolvingAgainstBaseURL:YES];
        components.query = nil;     // remove the query
        components.fragment = nil;
        NSString *url = [components URL].absoluteString;
        if (url.length > 0 && ![_cacheBlackList containsObject:url])
            [_cacheBlackList addObject:url];
    }
}

- (WKUserScript *)ajaxHookScript {
    if (!_ajaxHookScript) {
        NSString *ajaxhookStr = [WQAJavaScriptStrResource WQAAjaxHookString_js];;
        _ajaxHookScript = [[WKUserScript alloc] initWithSource:ajaxhookStr injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    }
    return _ajaxHookScript;
}

- (WKUserScript *)jsBridgeScript {
    if (!_jsBridgeScript) {
        NSString *a = [WQAJavaScriptStrResource WQAJavascriptBridgeString];
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"ajaxhook" ofType:@"js"];
//        NSString *scriptText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        _jsBridgeScript = [[WKUserScript alloc] initWithSource:a injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    }
    return _jsBridgeScript;
}
- (void)WQAReport:(NSString *)eventId event:(NSDictionary *)event {
    if (_WQAReportStateBlock) {
        _WQAReportStateBlock(eventId, event);
    }
}

- (void)addHTTPPostBody:(id)body postId:(NSString *)postId {
    WEAK_SELF_DECLARED
    dispatch_async(_postBodyQueue, ^{
        STRONG_SELF_BEGIN
        NSAssert([strongSelf.HTTPPostBodyDict objectForKey:postId] == nil, @"addHTTPPostBody failed repeat postId");
        [strongSelf.HTTPPostBodyDict setObject:body forKey:postId];
        STRONG_SELF_END
    });
}

- (id)HTTPPostBodyForKey:(NSString *)key {
    if (!key)
        return nil;
    __block id body = nil;
    WEAK_SELF_DECLARED
    dispatch_sync(_postBodyQueue, ^{
        STRONG_SELF_BEGIN
        body = strongSelf.HTTPPostBodyDict[key];
        [strongSelf.HTTPPostBodyDict removeObjectForKey:key];
        STRONG_SELF_END
    });
    return body;
}

- (void)setWebviewCacheLevel:(WQACacheState)webviewCacheLevel {
    if (webviewCacheLevel == WQACacheForbiddenIOS12) {
        NSString *version = [UIDevice currentDevice].systemVersion;
        if (version.doubleValue < 13.0f) {
            webviewCacheLevel = WQACacheWebviewPoolOnly;
        }
    }
#ifdef WQACacheOfflineSwitch
    if (webviewCacheLevel == WQACacheWebviewCleanMode) {
        [[WQAResourceManager sharedInstance] clearAllCache];
        webviewCacheLevel = WQACacheWebviewPoolOnly;
    }
#endif
    _webviewCacheLevel = webviewCacheLevel;
    logWebInfo([NSString stringWithFormat:@"setWebviewCacheLevel:%ld", _webviewCacheLevel]);
    if (_webviewCacheLevel == WQACacheStateOff) {
        _webviewPools = nil;
    }
    else if (!_webviewPools) {
        _webviewPools = [WQAWebviewPool new];
    }
}

//缓存黑名单
- (BOOL)isForbidenIntercept:(NSString *)url {
    if (self.webviewCacheLevel == WQACacheStateOff || self.webviewCacheLevel == WQACacheWebviewPoolOnly)
        return YES;
    if (!url || url.length == 0 || ![self isCacheTrustDomian:[NSURL URLWithString:url]])
        return YES;
    for (NSString *item in _cacheBlackList) {
        if ([url rangeOfString:item].location != NSNotFound)
            return YES;
    }
    return NO;
}

- (BOOL)isCacheTrustDomian:(NSURL *)url {
    BOOL isTrust = NO;
    if (url.absoluteString && url.host) {
        NSString *host = url.host;
        for (NSString *trustDomain in self.cacheTrustDomains) {
            if ([host hasSuffix:trustDomain]) {
                isTrust = YES;
                break;
            }
        }
    }
    return isTrust;
}

- (WQAWkWebview *)webviewInstanceByPool {
    if (_webviewCacheLevel == WQACacheStateOff)
        return nil;
    NSAssert([NSThread currentThread].isMainThread, @"webviewInstanceByPool should run on mainthread");
    if (!_webviewPools)
        _webviewPools = [WQAWebviewPool new];
    return [_webviewPools webviewInstanceByPool];
}

- (void)recycleWebview:(WQAWkWebview *)webview {
    NSAssert([NSThread currentThread].isMainThread, @"recycleWebview should run on mainthread");
    [webview endReuseTrace];
    if (_webviewCacheLevel != WQACacheStateOff) {
        [_webviewPools recycleWebview:webview];
    }
}

- (void)updateWebviewCountLimit:(NSInteger)limit {
    [_webviewPools updateWebviewCountLimit:limit];
}

@end
