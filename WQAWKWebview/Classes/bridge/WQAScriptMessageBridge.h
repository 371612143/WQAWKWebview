//
//  WQACommonScriptMessageHandler.h
//  WQACommonWkWebview
//
//  Created by matthew on 2019/3/20.
//  Copyright © 2019年 matthew. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "WQABridgeInvokeItem.h"


@class WQAWKWebViewController, WQAScriptMessageBridge;


@protocol WQAScriptMessageBridgeDelegate<NSObject>
@required
//运行一段js
- (void) messageHandler:(WQAScriptMessageBridge* _Nullable)messageHandler evaluateJavascript:(NSString *_Nullable)javascriptCommand;
//没在白名单列表的页面禁止调用JSAPI
- (BOOL) messageHandler:(WQAScriptMessageBridge* _Nullable)messageHandler isForbiddenJSAPICall:(NSString *_Nullable)apiName;

- (NSString *__nonnull) getCurrentUrl:(WQAScriptMessageBridge *_Nullable)messageHandler;
@end

#define REGISTER_SELECTOR_HANDLER_TARGET(handler, target, name)     invocationItem = [WQABridgeInvokeItem bridgeItemWithTarget:(target) selector:@selector(name:responseCallback:)];\
[(handler) registerInvocationForName:@#name invocation:invocationItem];

#define REGISTER_SELECTOR_HANDLER(handler, name)    REGISTER_SELECTOR_HANDLER_TARGET(handler, self, name)

NS_ASSUME_NONNULL_BEGIN

//WQAWkWebview 桥接类通过message-handler桥接web和原生
@interface WQAScriptMessageBridge : NSObject<WKScriptMessageHandler>

@property (nonatomic, weak)id<WQAScriptMessageBridgeDelegate> delegate;
@property (nonatomic, weak) WKUserContentController *userContentController;
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString*, WQABridgeInvokeItem*> *jsHandlerDict;

- (instancetype)initWithUserContentController:(WKUserContentController *)controller
                                     delegate:(id<WQAScriptMessageBridgeDelegate> )delegate;


//注册接口 用来绑定js方法与本地回调，可以重复注册只保留最新的实现
- (void)registerInvocationForName:(NSString *)name invocation:(WQABridgeInvokeItem *)invocation;
//反注册
- (void)unregisterForName:(NSString *)name;
//查询接口
- (WQABridgeInvokeItem *)javaScriptHandlerForName:(NSString *)name;
//返回所有注册的回调
- (NSArray *)allUsedJSHandler;
@end

NS_ASSUME_NONNULL_END
