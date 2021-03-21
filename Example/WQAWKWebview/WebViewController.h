//
//  ViewController.h
//  webviewtest
//
//  Created by matthew on 2019/5/21.
//  Copyright © 2019 matthew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WQAWkWebviewKit.h>
#import "HTWKWebViewBridgeHandlerLoad.h"

@interface WebViewController : UIViewController<WQAScriptMessageBridgeDelegate>

@property (nonatomic, strong)WQAWkWebview *webview;
@property (nonatomic, strong) HTWKWebViewBridgeHandlerLoad *bridgeHandlerLoad;
- (instancetype)initWithUrl:(NSString *)url;
- (void)loadurl:(NSString *)url;
- (void)resetWebview;
@end

