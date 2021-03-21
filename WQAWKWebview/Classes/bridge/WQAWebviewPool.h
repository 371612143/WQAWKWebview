//
//  WQAWebviewPool.h
//  WQAWebviewComponent
//
//  Created by matthew on 2019/10/31.
//

#import <Foundation/Foundation.h>

@class WQAWkWebview;
NS_ASSUME_NONNULL_BEGIN

@interface WQAWebviewPool : NSObject
- (WQAWkWebview *)webviewInstanceByPool;
- (void)recycleWebview:(WQAWkWebview *)webview;
- (void)updateWebviewCountLimit:(NSInteger)limit;
@end

NS_ASSUME_NONNULL_END
