//
//  WQABusinessScriptBridge.m
//
//  Created by matthew on 2019/4/10.
//

#import "WQABusinessScriptBridge.h"
#import "ObjcHelpFunc.h"
#import "WQAWebCommonDefine.h"
#import <BGWeakProxy.h>

@implementation WQABusinessScriptBridge

- (instancetype)initWithUserContentController:(WKUserContentController *)controller
                            webViewController:(id<WQAScriptMessageBridgeDelegate> ) delegate {
    if (self = [super init]) {
        self.jsHandlerDict = [NSMutableDictionary new];
        self.userContentController = controller;
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc {
    for (NSString *name in self.jsHandlerDict.allKeys) {
        [self.userContentController removeScriptMessageHandlerForName:name];
    }
}

- (void)registerInvocationForName:(NSString *)name invocation:(WQABridgeInvokeItem *)invocation {
    if (unlikely(!name || !invocation || !invocation.callEnabled)) {
        return;
    }
    if ([self javaScriptHandlerForName:name]) {
        [self unregisterForName:name];
    }
    BGWeakProxy *proxy = [BGWeakProxy proxyWithTarget:self];
    [self.userContentController addScriptMessageHandler:(id<WKScriptMessageHandler>)proxy name:name];
    [self.jsHandlerDict setObject:invocation forKey:name];
}

- (void)unregisterForName:(NSString *)name {
    if ([self javaScriptHandlerForName:name]) {
        [self.userContentController removeScriptMessageHandlerForName:name];
        [self.jsHandlerDict removeObjectForKey:name];
    }
}

#pragma mark bridge-for-webview
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    NSString* methodName = message.name;
    if ([methodName length] <= 0 || ![self javaScriptHandlerForName:methodName]) {
        return;
    }
    
    NSMutableArray *paramsArray = [[NSMutableArray alloc] init];
    id body = message.body; //Allowed types are NSNumber, NSString, NSDate, NSArray, NSDictionary, and NSNull.
    
    if ([body isKindOfClass:[NSNumber class]]  || [body isKindOfClass:[NSDate class]]) {
        [paramsArray addObject:body];
    }
    else if([body isKindOfClass:[NSString class]] && [(NSString*)body length] > 0) {
        [paramsArray addObject:body];
    }
    else if ([body isKindOfClass:[NSArray class]]) {
        [paramsArray addObjectsFromArray:(NSArray*)body];
    }
    else if ([body isKindOfClass:[NSDictionary class]]) {
        [paramsArray addObjectsFromArray:[(NSDictionary*)body allValues]];
    }else if ([body isKindOfClass:[NSNull class]]){
        
    }
    logWebInfo([NSString stringWithFormat:@"WQABusinessScriptBridge doInvokeMethod: %@", methodName]);
    WQABridgeInvokeItem *invokeItem = [self javaScriptHandlerForName:methodName];
    runOnMainThreadAsync(^{
        [invokeItem invokeWithArray:paramsArray responseCallback:^(NSDictionary * _Nullable error, NSDictionary * _Nullable data) {
            
        }];
    });

}
@end

