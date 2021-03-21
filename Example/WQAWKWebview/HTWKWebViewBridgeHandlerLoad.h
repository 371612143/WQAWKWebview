//
//  HTWKWebViewBridgeHandlerLoad.h
//  hellotalk
//
//  Created by matthew on 2019/4/13.
//

#import <UIKit/UIKit.h>
#import <WQAWkWebViewCommonHandler.h>
#import <WQABusinessScriptBridge.h>

@class WKUserContentController, HLCommonWKWebViewController;

@interface HTWKWebViewBridgeHandlerLoad : NSObject
@property (nonatomic, strong)WQABusinessScriptBridge *originalBridge; //旧接口的桥
@property (nonatomic, strong)WQAScriptMessageBridge *WQAScriptBridge; //新接口的桥

- (instancetype)initWithContentController:(WKUserContentController *)ContentController viewController:(UIViewController *)viewController;
@end

