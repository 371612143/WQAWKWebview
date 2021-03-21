//
//  WQABridgeHandlerInvokeItem.m
//  WQAWebview
//
//  Created by matthew on 2019/3/23.
//  Copyright © 2019年 matthew. All rights reserved.
//

#import "WQABridgeInvokeItem.h"
#import <objc/message.h>
#import "WQAWebEnvironment.h"
#import <UIKit/UIKit.h>


const NSString *WQACancelListenerKey = @"removeEventListener";
const NSString *WQAErrorMessageKey = @"message";
const NSString *WQAErrorCodeKey = @"code";

@interface WQABridgeInvokeItem()
@property (nonatomic, weak)id target;
@property (nonatomic, assign)SEL selector;
@property (nonatomic, strong)WQAJavaScriptHandler javaScriptHandler;
@end

@implementation WQABridgeInvokeItem

+ (instancetype)bridgeItemWithTarget:(id)target selector:(SEL)selector {
    WQABridgeInvokeItem *item = [[self class] new];
    item.target = target;
    item.selector = selector;
    item.javaScriptHandler = nil;
    return item;
}

+ (instancetype)bridgeItemWithHandler:(id)target handler:(WQAJavaScriptHandler)handler {
    WQABridgeInvokeItem *item = [[self class] new];
    item.target = target;
    item.javaScriptHandler = handler;
    item.selector = nil;
    return item;
}

- (void)dealloc {
    _target = nil;
    _selector = nil;
    _javaScriptHandler = nil;
}

//performselect  nsinvocation  imp(), objc_msgsend, direct
- (void)invoke:(WQAJBMessage *)params responseCallback:(WQAResponseCallback)responseCallback {
    if (unlikely(!self.callEnabled)) {
        goto WQA_empty_implemention;
    }
    if (_selector && [_target respondsToSelector:_selector]) {
        NSMethodSignature *sig = [_target methodSignatureForSelector:_selector];
        if (unlikely(!sig || sig.numberOfArguments != 4)) {
            goto WQA_empty_implemention;
        }
        NSInvocation *invocationItem = [NSInvocation invocationWithMethodSignature:sig];
        invocationItem.target = _target;
        invocationItem.selector = _selector;
        
        [invocationItem setArgument:&params atIndex:2];
        [invocationItem setArgument:&responseCallback atIndex:3];
        [invocationItem invoke];
        return;
    }
    else if (likely(_javaScriptHandler)) {
        self.javaScriptHandler(params, responseCallback);
        return;
    }
    
WQA_empty_implemention:
    if (likely(responseCallback)) {
        NSString *logInfo = [NSString stringWithFormat:@"target:%@ method: %@ not impletion", _target, NSStringFromSelector(_selector)];
        WQAErrorMessage *error = @{WQAErrorCodeKey: @(WQAResponseNotImplemetion), @"message": logInfo};
        responseCallback(nil, error);
    }
    return;
    
}

- (BOOL)callEnabled {
    if (_target && _selector && [_target respondsToSelector:_selector]) {
        return YES;
    }
    if (likely(_javaScriptHandler)) {
        return YES;
    }
    return NO;
}

- (void)invokeWithArray:(NSArray *)params responseCallback:(WQAResponseCallback)responseCallback {
    NSMethodSignature *signature = nil;
    NSUInteger paramsNum = 0;
    if (![self callEnabled]) {
        goto WQA_error_invoke;
    }
    signature = [self.target methodSignatureForSelector:self.selector];
    if (!signature) {
        goto WQA_error_invoke;
    }
    paramsNum = signature.numberOfArguments;
    if ((paramsNum - 2) != params.count) {//有两个隐含参数 self，sel，所以减去2
        goto WQA_error_invoke;
    }
    else {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self.target];
        [invocation setSelector:self.selector];
        
        for (int i = 0; i < paramsNum - 2; i++)
        {
            //判断参数类型，防止web页传入的类型不正确
            // getArgumentTypeAtIndex @ 表示 NSObject*或id类型  :表示SEL类型  i表示int类型
            NSString* argumentTypeString = [NSString stringWithFormat:@"%s", [signature getArgumentTypeAtIndex:(i+2)]];
            id obj = params[i];
            
            if ([argumentTypeString isEqualToString:@"@"]) { // id
                [invocation setArgument:&obj atIndex:i + 2];
            }  else if ([argumentTypeString isEqualToString:@"B"]) { // bool
                bool objVaule = [obj boolValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"f"]) { // float
                float objVaule = [obj floatValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"d"]) { // double
                double objVaule = [obj doubleValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"c"]) { // char
                char objVaule = [obj charValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"i"]) { // int
                int objVaule = [obj intValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"I"]) { // unsigned int
                unsigned int objVaule = [obj unsignedIntValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"S"]) { // unsigned short
                unsigned short objVaule = [obj unsignedShortValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"L"]) { // unsigned long
                unsigned long objVaule = [obj unsignedLongValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"s"]) { // shrot
                short objVaule = [obj shortValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"l"]) { // long
                long objVaule = [obj longValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"q"]) { // long long
                long long objVaule = [obj longLongValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"C"]) { // unsigned char
                unsigned char objVaule = [obj unsignedCharValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"Q"]) { // unsigned long long
                unsigned long long objVaule = [obj unsignedLongLongValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"{CGRect={CGPoint=dd}{CGSize=dd}}"]) { // CGRect
                CGRect objVaule = [obj CGRectValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            } else if ([argumentTypeString isEqualToString:@"{UIEdgeInsets=dddd}"]) { // UIEdgeInsets
                UIEdgeInsets objVaule = [obj UIEdgeInsetsValue];
                [invocation setArgument:&objVaule atIndex:i + 2];
            }else{
                [invocation setArgument:&obj atIndex:i+2];
            }
        }
        [invocation invoke];
        return;
    }
    
    
WQA_error_invoke:
    if (likely(responseCallback)) {
        NSString *logInfo = [NSString stringWithFormat:@"target:%@ method: %@ not impletion", _target, NSStringFromSelector(_selector)];
        WQAErrorMessage *error = @{WQAErrorCodeKey: @(WQAResponseNotImplemetion), @"message": logInfo};
        responseCallback(nil, error);
    }
    return;
}

@end
