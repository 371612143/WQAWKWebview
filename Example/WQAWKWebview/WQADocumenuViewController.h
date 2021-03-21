//
//  WQADocumenuViewController.h
//  WQAWebviewComponent
//
//  Created by matthew on 2019/9/27.
//

#import <Foundation/Foundation.h>
#import <WQAWkWebviewKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WQADocumenuViewController : UIDocumentMenuViewController
- (instancetype)initWithJSCallback:(WQAResponseCallback)callback;
@end

NS_ASSUME_NONNULL_END
