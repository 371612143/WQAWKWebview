//
//  ViewController.m
//  webviewtest
//
//  Created by matthew on 2019/5/21.
//  Copyright © 2019 matthew. All rights reserved.
//

#import "WebViewController.h"
#import <WQAResourceManager.h>



@interface WebViewController ()<WQANavigationDelegate>
@property (nonatomic, strong)NSArray* domainWhiteList;
@property (nonatomic, strong)NSURL* currentURL;
@property (nonatomic, strong) WQAResourceManager *resourceDownload;
@end

@implementation WebViewController


- (instancetype)initWithUrl:(NSString *)url {
    if (self = [super init]) {
        _currentURL = [NSURL URLWithString:url];
    }
    return self;
}

- (void)loadurl:(NSString *)url {
    _currentURL = [NSURL URLWithString:url];
    [self.webview loadRequest:[NSURLRequest requestWithURL:_currentURL]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _resourceDownload = [WQAResourceManager sharedInstance];

    
    [self.webview loadRequest:[NSURLRequest requestWithURL:_currentURL]];
    [self.view addSubview:self.webview];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSLog(@"viewWillDisappear WebViewController %@", @([date timeIntervalSince1970]));
}

- (void)dealloc {
    [self resetWebview];
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSLog(@"dealloc WebViewController %@", @([date timeIntervalSince1970]));
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
}

#pragma mark WQAScriptMessageBridgeDelegate
- (void)messageHandler:(WQAScriptMessageBridge *)messageHandler evaluateJavascript:(NSString *)javascriptCommand {
    [self.webview evaluateJavaScript:javascriptCommand completionHandler:^(id data, NSError * _Nullable error) {
        
    }];
}

- (BOOL)messageHandler:(WQAScriptMessageBridge *)messageHandler isForbiddenJSAPICall:(NSString *)apiName {
    return !self.webview.isTrustDomain;
}

- (NSString *)getCurrentUrl:(WQAScriptMessageBridge *)messageHandler {
    return self.currentURL.absoluteString;
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    //[self.webview loadRequest:[NSURLRequest requestWithURL:_currentURL]];
}
#pragma mark -- WQANavigationDelegate
- (NSURL *)webview:(WQAWkWebview *)webview getHostReplaceUrl:(NSURL *)requestUrl {
    return requestUrl;
}

- (NSArray *)domainWhiteList {
    return @[@"doc.weixin.qq.com",  @"ocmock.org", @"163.com"];
}

- (void)resetWebview {
    [_webview stopLoading];
    [_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
    [_webview.configuration.userContentController removeAllUserScripts];
    [_webview removeObserver:self forKeyPath:@"title"];
    [_webview removeObserver:self forKeyPath:@"canGoBack"];
    _bridgeHandlerLoad = nil;
    [WQAEnvironmentInstance recycleWebview:_webview];
    _webview = nil;
}

- (WQAWkWebview *)webview {
    if (!_webview) {
        _webview = [WQAEnvironmentInstance webviewInstanceByPool];
        NSLog(@"load_time :%@", _webview);
        if (_webview) {
            _webview.frame = self.view.bounds;
        }
        else {
            _webview = [[WQAWkWebview alloc] initWithFrame:self.view.bounds];
        }
        _webview.WQANavigationDelegate = self;
        _bridgeHandlerLoad = [[HTWKWebViewBridgeHandlerLoad alloc] initWithContentController:_webview.configuration.userContentController viewController:self];
//        [_webview.configuration.userContentController addUserScript:[self jsTestScript]];
        NSMutableArray *domainList = [NSMutableArray arrayWithArray:self.domainWhiteList];
        [_webview setTrustDomains:domainList blackDomains:@[] redirectUrl:@""];
        [_webview addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [_webview addObserver:self forKeyPath:@"canGoBack" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
    return _webview;
}

- (WKUserScript *)jsTestScript {
    static WKUserScript *jsTestScript;
    if (!jsTestScript) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"js"];
        NSString *scriptText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        jsTestScript = [[WKUserScript alloc] initWithSource:scriptText injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    }
    return jsTestScript;
}
@end
