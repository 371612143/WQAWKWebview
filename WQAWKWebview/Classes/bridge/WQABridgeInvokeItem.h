//
//  WQABridgeHandlerInvokeItem.h
//  WQAWebview
//
//  Created by matthew on 2019/3/23.
//  Copyright © 2019年 matthew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WQAWebCommonDefine.h"



//error  {code:11,data{},msg:'get token error'}

typedef NS_ENUM(NSInteger, WQAErrorCode) {
    WQAResponseSucessed = 0,
    WQAResponseParamError = 101,
    WQAResponseNotImplemetion = 102,
    WQAResponseApiForbidden = 103,
};

#define WQAResponse_Callback_Sucess if (responseCallback) {\
responseCallback(nil, nil);\
}

typedef NSDictionary WQAJBMessage;
typedef NSDictionary WQAErrorMessage;


typedef void(^WQAResponseCallback)(NSDictionary* _Nullable data, NSDictionary* _Nullable error);
typedef void(^WQAJavaScriptHandler)(id _Nullable data, WQAResponseCallback _Nullable responseCallback);

NS_ASSUME_NONNULL_BEGIN

extern const NSString *WQACancelListenerKey;
extern const NSString *WQAErrorMessageKey;
extern const NSString *WQAErrorCodeKey;

@interface WQABridgeInvokeItem : NSObject
@property (nonatomic, weak, readonly)id target;
@property (nonatomic, assign, readonly)SEL selector; //((id (*)(id, SEL, NSDictionary*, WQAResponseCallback)) (void*) Func)
@property (nonatomic, strong, readonly)WQAJavaScriptHandler javaScriptHandler;

+ (instancetype)bridgeItemWithHandler:(id)target handler:(WQAJavaScriptHandler)handler;
+ (instancetype)bridgeItemWithTarget:(id)target selector:(SEL)selector;

- (void)invoke:(WQAJBMessage *)params responseCallback:(WQAResponseCallback)responseCallback;
- (void)invokeWithArray:(NSArray *)params responseCallback:(WQAResponseCallback)responseCallback;
- (BOOL)callEnabled;
@end

NS_ASSUME_NONNULL_END
