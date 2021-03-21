//
//  WQAWebviewPool.m
//  WQAWebviewComponent
//
//  Created by matthew on 2019/10/31.
//

#import "WQAWebviewPool.h"
#import "WQAWebCommonDefine.h"
#import <WQAWkWebviewKit.h>
#if __has_include(<WQAOfflineUtil.h>)
#import "WQAOfflineUtil.h"
#endif
@interface WQAWebviewPool()
@property (nonatomic, assign)NSInteger webviewCountLimit;
@property (nonatomic, strong)NSMutableArray<WQAWkWebview *> *usedList;
@property (nonatomic, strong)NSMutableArray<WQAWkWebview *> *freeList;
@end

@implementation WQAWebviewPool

- (instancetype)init {
    if (self = [super init]) {
        _usedList = [NSMutableArray new];
        _freeList = [NSMutableArray new];
        _webviewCountLimit = 2;
        [self _prepareNextWebview];
        WQAWkWebview *webview = [self creatWKWebview];
        [self.freeList addObject:webview];
    }
    return self;
}

- (void)dealloc {
    [NOTIFICATION_CENTER removeObserver:self];
}


- (WQAWkWebview *)creatWKWebview {
    WQAWkWebview *webview = nil;
    if (WQAEnvironmentInstance.createWKWebviewBlock) {
        webview = WQAEnvironmentInstance.createWKWebviewBlock();
    } else {
        webview = [[WQAWkWebview alloc] initWithFrame:CGRectZero];
    }
    return webview;
}

- (void)updateWebviewCountLimit:(NSInteger)limit {
    WEAK_SELF_DECLARED
    runOnMainThread(^{
        STRONG_SELF_BEGIN
        strongSelf.webviewCountLimit = limit;
        STRONG_SELF_END
    });
}

- (WQAWkWebview *)webviewInstanceByPool {
    [self _prepareNextWebview];
    if (_freeList.count == 0) {
        return nil;
    }
    __block WQAWkWebview *webview = nil;
    WEAK_SELF_DECLARED
    runOnMainThread(^{
        STRONG_SELF_BEGIN
        webview = [strongSelf.freeList lastObject];
        [webview prepaeForReuse];
        [strongSelf.freeList removeLastObject];
        [strongSelf.usedList addObject:webview];
        [strongSelf _prepareNextWebview];
        STRONG_SELF_END
    });
    return webview;
}

- (void)recycleWebview:(WQAWkWebview *)webview {
    WEAK_SELF_DECLARED
    runOnMainThread(^{
        STRONG_SELF_BEGIN
        if (!webview || ![strongSelf.usedList containsObject:webview]) {
            return;
        }
        [strongSelf.usedList removeObject:webview];
        [strongSelf.freeList addObject:webview];
#ifdef WQACacheOfflineSwitch
        if (strongSelf.usedList.count == 0)
            [WQAOfflineUtil turnOffCache];
#endif
        STRONG_SELF_END
    });
}

- (void)_prepareNextWebview {
    WEAK_SELF_DECLARED
    runOnMainThread(^{
        STRONG_SELF_BEGIN
        if (strongSelf.freeList.count > 0)
            return;
        if (strongSelf.freeList.count + strongSelf.usedList.count >= strongSelf.webviewCountLimit)
            return;
        WQAWkWebview *webview = [strongSelf creatWKWebview];
        [strongSelf.freeList addObject:webview];
        STRONG_SELF_END
    });
}

@end
