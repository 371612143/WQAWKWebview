//
//  WQAWKWebViewCommonHandler.m
//  WQAWebviewComponent
//
//  Created by matthew on 2019/4/9.
//  Copyright © 2019年 matthew. All rights reserved.
//

#include "WQAWkWebviewKit.h"
#import "WQAWkWebViewCommonHandler.h"
#import "WQAWebEnvironment.h"

@interface WQAWKWebViewCommonHandler()

@end

@implementation WQAWKWebViewCommonHandler

- (instancetype)initWithScriptBridge:(WQAScriptMessageBridge*)bridge {
    if (self = [super init]) {
        _scriptMessageHandler = bridge;
        [self preLoadCommonJSHandler];
    }
    return self;
}

- (void)dealloc {
    [NOTIFICATION_CENTER removeObserver:self];
}

- (void)preLoadCommonJSHandler {
    WQABridgeInvokeItem *invocationItem = nil;
    WQAScriptMessageBridge *handler = self.scriptMessageHandler;
    
    //通用接口只保留4个
    //通用类 http://172.24.25.17:9000/public/
    REGISTER_SELECTOR_HANDLER(handler, caniuse)
    REGISTER_SELECTOR_HANDLER(handler, sdkVersion)
    REGISTER_SELECTOR_HANDLER(handler, DeviceInfo)
    REGISTER_SELECTOR_HANDLER(handler, Clipboard)
    REGISTER_SELECTOR_HANDLER(handler, onAjaxHookPost)
}

//返回所有可用接口
- (void)caniuse:(NSDictionary *)params responseCallback:(WQAResponseCallback)responseCallback {
    NSArray *allHandlers = [self.scriptMessageHandler allUsedJSHandler];
    responseCallback(@{@"methods": allHandlers}, nil);
}
//返回sdk版本
- (void)sdkVersion:(NSDictionary *)params responseCallback:(WQAResponseCallback)responseCallback {
    responseCallback(@{@"value":@"1.0.0"}, nil);
}

+ (NSString *)composedAppVersionInfo {
    static NSString *composedAppVersionInfo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        composedAppVersionInfo = [NSString stringWithFormat:@"%@(%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    });
    return composedAppVersionInfo;
}


- (void)DeviceInfo:(NSDictionary *)params responseCallback:(WQAResponseCallback)responseCallback {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    BOOL networkStatus = YES;//[NetUtil isNetworkAvaiable];
    NSDictionary *statusDict = @{
                                 @"appVersion" : [WQAWKWebViewCommonHandler composedAppVersionInfo] ?: @"",
                                 @"osName" : [UIDevice currentDevice].systemName,
                                 @"osVersion" : [UIDevice currentDevice].systemVersion,
                                 @"deviceModel" : [UIDevice currentDevice].model,
                                 @"deviceName" : [UIDevice currentDevice].name,
                                 @"appName" : [infoDict objectForKey:@"CFBundleDisplayName"] ? : @"",
                                 @"appIdentifier" :  [NSBundle mainBundle].bundleIdentifier ? : @"",
                                 @"localeCountryCode" : [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] ?: @"",
                                 @"networkStatus" : @(networkStatus)
                                 };
    if (responseCallback) {
        responseCallback(statusDict, nil);
    }
}

- (void)Clipboard:(NSDictionary *)params responseCallback:(WQAResponseCallback)responseCallback {
    NSString *opMode = params[@"mode"];
    NSDictionary *retDict = nil;
    NSDictionary *errDict = nil;
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    if ([opMode isEqualToString:@"readText"]) {
        retDict = @{@"textValue": pasteBoard.string ? : @""};
    }
    else if ([opMode isEqualToString:@"writeText"]) {
        NSString *text = params[@"textValue"];
        if (text.length == 0) {
            pasteBoard.string = @"";
        }
        else if (text.length < 500) {
            pasteBoard.string =  text;
        }
        else {
            errDict = @{WQAErrorCodeKey: @(WQAResponseParamError), WQAErrorMessageKey: @"textValue length error"};
        }
    }
    else {
        errDict = @{WQAErrorCodeKey: @(WQAResponseParamError), WQAErrorMessageKey:@"interface does not support images copy"};
    }
    
    if (responseCallback) {
        responseCallback(retDict, errDict);
    }
}

- (void)onAjaxHookPost:(NSDictionary *)params responseCallback:(WQAResponseCallback)responseCallback {
    if (params[@"postId"] && params[@"body"]) {
        [WQAEnvironmentInstance addHTTPPostBody:params[@"body"] postId:params[@"postId"]];
    }
    responseCallback(nil, nil);
}
@end
