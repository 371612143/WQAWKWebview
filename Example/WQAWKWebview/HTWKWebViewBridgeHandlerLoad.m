//
//  HTWKWebViewBridgeHandlerLoad.m
//  hellotalk
//
//  Created by matthew on 2019/4/13.
//
#import "HTWKWebViewBridgeHandlerLoad.h"
#import <WQAResourceManager.h>
#import "WQADocumenuViewController.h"

@interface HTWKWebViewBridgeHandlerLoad()
@property (nonatomic, strong)WQAWKWebViewCommonHandler *WQACommonHandler;  //sdk通用接口
@property (nonatomic, weak)UIViewController *bussinessVC;
@end

@implementation HTWKWebViewBridgeHandlerLoad

- (instancetype)initWithContentController:(WKUserContentController *)contentController viewController:(UIViewController<WQAScriptMessageBridgeDelegate> *)viewController {
    if (self = [super init]) {
        self.bussinessVC = viewController;
        self.originalBridge = [[WQABusinessScriptBridge alloc] initWithUserContentController:contentController webViewController:viewController];
        self.WQAScriptBridge = [[WQAScriptMessageBridge alloc] initWithUserContentController:contentController delegate:viewController];
        [self loadWQABridgeHandler];
        //开放caniuse 和sdkversion
        self.WQACommonHandler = [[WQAWKWebViewCommonHandler alloc] initWithScriptBridge:self.WQAScriptBridge];
        [self.WQACommonHandler preLoadCommonJSHandler];
    }
    return self;
}


//y统一webview sdk业务相关api
#pragma mark--register handler
- (void)loadWQABridgeHandler {
    WQABridgeInvokeItem *invocationItem = nil;
    WQAScriptMessageBridge *handler = self.WQAScriptBridge;
    REGISTER_SELECTOR_HANDLER(handler, uploadPickerFile)
    REGISTER_SELECTOR_HANDLER(handler, showJascriptRunError)
    
    invocationItem = [WQABridgeInvokeItem bridgeItemWithTarget:self selector:@selector(getDeviceInfo:)];
    [self.originalBridge registerInvocationForName:@"DeviceInfo" invocation:invocationItem];
    
    invocationItem = [WQABridgeInvokeItem bridgeItemWithHandler:self handler:^(id  _Nullable data, WQAResponseCallback  _Nullable responseCallback) {
        
    }];
    [self.originalBridge registerInvocationForName:@"DeviceInfoBlock" invocation:invocationItem];
    [self.WQAScriptBridge registerInvocationForName:@"DeviceInfoBlock" invocation:invocationItem];
}

- (void)getDeviceInfo:(id)params {
    
}

- (void)showJascriptRunError:(NSDictionary *)params responseCallback:(WQAResponseCallback)responseCallback {
    //NSAssert(NO, @"showJascriptRunError");
}

- (void)uploadPickerFile:(NSDictionary *)params responseCallback:(WQAResponseCallback)responseCallback{
    WQADocumenuViewController *docVC = [[WQADocumenuViewController alloc] initWithJSCallback:responseCallback];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:docVC animated:YES completion:nil];
}



#pragma mark common api


@end
