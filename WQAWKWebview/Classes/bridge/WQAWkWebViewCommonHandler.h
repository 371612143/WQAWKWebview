//
//  WQAWKWebViewCommonHandler.h
//  WQAWebviewComponent
//
//  Created by matthew on 2019/4/9.
//  Copyright © 2019年 matthew. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class WQAScriptMessageBridge;
@interface WQAWKWebViewCommonHandler : NSObject

- (void)preLoadCommonJSHandler;

@property (nonatomic, strong) WQAScriptMessageBridge *scriptMessageHandler;

- (instancetype)initWithScriptBridge:(WQAScriptMessageBridge*)bridge;
@end

NS_ASSUME_NONNULL_END
