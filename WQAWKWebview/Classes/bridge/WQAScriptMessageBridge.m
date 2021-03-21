//
//  WQACommonScriptMessageHandler.m
//  WQACommonWkWebview
//
//  Created by matthew on 2019/3/20.
//  Copyright © 2019年 matthew. All rights reserved.
//

#import "ObjcHelpFunc.h"
#import "WQAScriptMessageBridge.h"
#import "WQAWebEnvironment.h"
#import <BGWeakProxy.h>

@implementation WQAScriptMessageBridge

static NSString *methodNameKey = @"method";
static NSString *paramKey = @"params";
static NSString *idKey = @"id";
static NSString *resultKey = @"result";
static NSString *jsonrpcKey = @"jsonrpc";

- (instancetype)initWithUserContentController:(WKUserContentController *)controller delegate:(id<WQAScriptMessageBridgeDelegate>) delegate {
    if (self = [super init]) {
        _jsHandlerDict = [NSMutableDictionary new];
        _userContentController = controller;
        _delegate = delegate;
        //添加全局回调入口
        BGWeakProxy *proxy = [BGWeakProxy proxyWithTarget:self];
        [_userContentController addScriptMessageHandler:(id<WKScriptMessageHandler>)proxy name:@"postMessageToNative"];
        //NSString *jsCode = WQAWkWebview_JSBridgeCode();
        //[self _evaluateJavaScript:jsCode];
    }
    return self;
}

- (void)dealloc {
    [self.userContentController removeAllUserScripts];
    [self.userContentController removeScriptMessageHandlerForName:@"postMessageToNative"];
    self.jsHandlerDict = nil;
    self.userContentController = nil;
}

- (void) _evaluateJavaScript:(NSString *)javascriptCommand {
    WEAK_SELF_DECLARED
    runOnMainThreadAsync(^{
        if ([weakSelf.delegate respondsToSelector:@selector(messageHandler:evaluateJavascript:)]) {
            [weakSelf.delegate messageHandler:self evaluateJavascript:javascriptCommand];
        }
    });
}

#pragma mark bridge-for-webview
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *selectorName = message.name;
    if (unlikely(selectorName.length == 0
                 || ![message.body isKindOfClass:[NSString class]])) {
        return;
    }
    NSString *body = (NSString *)message.body;
    [self doInvokeMethod:body];
}
 
- (void)doInvokeMethod:(NSString *)messageBody {
    //var dic = {handlerName:handlerName, param:JSON.stringify(params), id:""+handler, jsonrpcKey:jsonrpc2.0};
    
    NSError *error = nil;
    NSData *body = [messageBody dataUsingEncoding:NSUTF8StringEncoding];
    id jsonBody = [NSJSONSerialization JSONObjectWithData:body options:kNilOptions error:&error];
    if (unlikely(![jsonBody isKindOfClass:[NSDictionary class]])) {
        return [self _responseJSCallError:WQAResponseParamError method:@"empty_method_name" params:@"{}" callbackId:@"empty_cbid"];
    }
    
    __block NSDictionary *argumentDict = [NSDictionary dictionaryWithDictionary:jsonBody];
    if (unlikely(argumentDict.allKeys.count != 4 || ![argumentDict[methodNameKey] isKindOfClass:[NSString class]]
                 || (![argumentDict[paramKey] isKindOfClass:[NSString class]] && ![argumentDict[paramKey] isKindOfClass:[NSDictionary class]])
                 || ![argumentDict[idKey] isKindOfClass:[NSString class]])) {
        return [self _responseJSCallError:WQAResponseParamError method:@"empty_method_name" params:@"{}" callbackId:@"empty_cbid"];
    }
    __block id handlerName = argumentDict[methodNameKey];
    if (unlikely(![handlerName isKindOfClass:[NSString class]] || ![self javaScriptHandlerForName:handlerName])) {
        return [self _responseJSCallError:WQAResponseNotImplemetion method:handlerName params:argumentDict[paramKey] callbackId:argumentDict[idKey]];
    }
    
    id params = nil;
    if ([argumentDict[paramKey] isKindOfClass:[NSString class]]) {
        NSData *jsonData = [argumentDict[paramKey] dataUsingEncoding:NSUTF8StringEncoding];
        params = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        if (unlikely(![params isKindOfClass:[NSDictionary class]])) {
            return [self _responseJSCallError:WQAResponseParamError method:handlerName params:argumentDict[paramKey] callbackId:argumentDict[idKey]];
        }
    } else {
        params = argumentDict[paramKey];
    }
    
    logWebInfo([NSString stringWithFormat:@"WQAScriptMessageBridge doInvokeMethod: %@", handlerName]);
    //需要在js中运行callback代码
    __block NSString *callbackId = argumentDict[idKey];
    WQAResponseCallback responseCallBack = nil;
    
    WEAK_SELF_DECLARED
    if (callbackId && ![params[WQACancelListenerKey] boolValue]) {
        responseCallBack = ^(id responseData, id error) {
            STRONG_SELF_BEGIN
            responseData = responseData == nil ? @{} : responseData;
            WQAJBMessage *msg = nil;
            if (error) {
                NSInteger code = [error[WQAErrorCodeKey] integerValue];
                [strongSelf _responseJSCallError:code method:handlerName params:argumentDict[paramKey] callbackId:callbackId];
            }
            else {
                msg = @{idKey:callbackId, methodNameKey:handlerName, resultKey:responseData, jsonrpcKey:@"2.0"};
                [strongSelf _queueMessage:msg];
            }
            STRONG_SELF_END
        };
    }
    else {
        //对于监听类的api 如果是WQACancelListenerKey触发的调用 responseCallback是一个空操作，不会触发任何web回调
        responseCallBack = ^(NSDictionary *responseData, NSDictionary *error) { };
    }
    
    //没在白名单列表的页面禁止调用JSAPI
    if ([self.delegate respondsToSelector: @selector(messageHandler:isForbiddenJSAPICall:)]
        && [self.delegate messageHandler:self isForbiddenJSAPICall:handlerName]) {
        responseCallBack(nil, @{WQAErrorCodeKey:@(WQAResponseApiForbidden)});
        [self _responseJSCallError:WQAResponseApiForbidden method:handlerName params:argumentDict[paramKey] callbackId:callbackId];
        return;
    }
    
    WQABridgeInvokeItem *invokeItem = [self javaScriptHandlerForName:handlerName];
    runOnMainThreadAsync(^{
        [invokeItem invoke:params responseCallback:responseCallBack];
    });
    
}

- (void)_responseJSCallError:(NSInteger)type method:(NSString *)method params:(NSString *)params callbackId:(NSString *)callbackId{
    if (!method || !params || !callbackId) {
        return;
    }
    NSString *url = @"";
    if ([self.delegate respondsToSelector:@selector(getCurrentUrl:)]) {
        url = [self.delegate getCurrentUrl:self];
        if (!url || url.length == 0) {
            url = @"";
        }
    }
    NSDictionary *errorDict = @{WQAErrorCodeKey:@(type).stringValue, @"method":method, @"params":params, @"cur_url":url};
    WQAWebReport(WQAStatisticsEventJSAPICallError, errorDict);
    NSDictionary *msg = @{idKey:callbackId, methodNameKey:method, @"error":@{@"code":@(type)}, jsonrpcKey:@"2.0"};
    [self _queueMessage:msg];
}

- (void)_queueMessage:(WQAJBMessage*)message {
    [self _dispatchMessage:message];
}

- (void)_dispatchMessage:(NSDictionary *)message {
    NSString *messageJSON = [self _serializeMessage:message pretty:NO];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    NSString* javascriptCommand = [NSString stringWithFormat:@"window.wqaJsBridge.postMessageByNative('%@');", messageJSON];
    //ajaxhook 的方法需要特殊的回调
    if ([message[methodNameKey] isEqualToString:@"onAjaxHookPost"]) {
        javascriptCommand = [NSString stringWithFormat:@"window.ajaxHookPostCallback('%@');", messageJSON];
    }
    [self _evaluateJavaScript:javascriptCommand];
}

- (NSString *)_serializeMessage:(id)message pretty:(BOOL)pretty{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:(NSJSONWritingOptions)(pretty ? NSJSONWritingPrettyPrinted : 0) error:nil] encoding:NSUTF8StringEncoding];
}

#pragma--mark registerCallBack
- (void)registerInvocationForName:(NSString *)name invocation:(WQABridgeInvokeItem *)invocation {
    if (unlikely(!name || !invocation || !invocation.callEnabled)) {
        return;
    }
    [self.jsHandlerDict setObject:invocation forKey:name];
}

- (void)unregisterForName:(NSString *)name {
    [self.jsHandlerDict removeObjectForKey:name];
}

- (WQABridgeInvokeItem *)javaScriptHandlerForName:(NSString *)name {
    if (unlikely(!name || name.length == 0)) {
        return nil;
    }
    id jsHandler = [self.jsHandlerDict objectForKey:name];
    if (jsHandler) {
        return jsHandler;
    }
    return nil;
}

- (NSArray *)allUsedJSHandler {
    NSArray *allHandlers = [NSArray arrayWithArray:[self.jsHandlerDict allKeys]];
    return allHandlers;
}
@end

