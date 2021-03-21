//
//  WQAOfflineUtil.m
//  WQAWebviewComponent
//
//  Created by matthew on 2019/8/14.
//

#import "WQAOfflineUtil.h"
#import "NSURLProtocol+WQAAdd.h"
#import "WQACustomURLProtocol.h"
#import "WQAWebEnvironment.h"

static BOOL kOfflineCacheSwitch = NO;

@implementation WQAOfflineUtil

+ (void)switchOnOfflineCache:(NSString *)applestsConfigUrl {
    @synchronized (@(kOfflineCacheSwitch)) {
        if (kOfflineCacheSwitch || !applestsConfigUrl || applestsConfigUrl.length == 0
            || WQAEnvironmentInstance.webviewCacheLevel == WQACacheStateOff
            || WQAEnvironmentInstance.webviewCacheLevel == WQACacheWebviewPoolOnly) {
            return;
        }
        kOfflineCacheSwitch = YES;
        [NSURLProtocol registerClass:[WQACustomURLProtocol class]];
        [NSURLProtocol wk_registerScheme:@"http"];
        [NSURLProtocol wk_registerScheme:@"https"];
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [WQAResourceManager sharedInstance].appletsConfigUrl = applestsConfigUrl;
        });
    }

}

+ (void)turnOffCache {
    @synchronized (@(kOfflineCacheSwitch)) {
        if (kOfflineCacheSwitch) {
            [NSURLProtocol wk_unregisterScheme:@"http"];
            [NSURLProtocol wk_unregisterScheme:@"https"];
            [NSURLProtocol unregisterClass:[WQACustomURLProtocol class]];
            kOfflineCacheSwitch = NO;
        }
    }
}

+ (NSString *)appletsIDFromURL:(NSURL *)url {
    if (!url || url.absoluteString.length == 0) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    
    NSArray *queryItems = components.queryItems;
    NSString *appletsID = nil;
    for (NSURLQueryItem *item in queryItems) {
        if ([item.name isEqualToString:@"appletsID"]) {
            appletsID = item.value;
            break;
        }
    }
    return appletsID;
}


+ (NSString *)appletsIDFromRequest:(NSURLRequest *)request {
    NSURL *url = request.mainDocumentURL ? : request.URL;
    return [WQAOfflineUtil appletsIDFromURL:url];
}


+ (NSURL *)urlByDeletingParameters:(NSURL *)url
{
    if (!url || url.absoluteString.length == 0)
        return url;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    components.query = nil;     // remove the query
    components.fragment = nil;    
    return [components URL];
}

@end
