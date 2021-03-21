//
//  WQABusinessScriptBridge.h
//
//  Created by matthew on 2019/4/10.
//

#import "WQAScriptMessageBridge.h"

//旧版本接口的桥
//为了让页面兼容WQA和业务端的旧版本接口必须把旧的逻辑用wkwebview-message-handler实现一遍
@interface WQABusinessScriptBridge : WQAScriptMessageBridge

- (instancetype)initWithUserContentController:(WKUserContentController *)controller
                            webViewController:(id<WQAScriptMessageBridgeDelegate> ) delegate;

@end

