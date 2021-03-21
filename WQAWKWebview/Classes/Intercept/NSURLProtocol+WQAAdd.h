//
//  NSURLProtocol+WQAAdd.h
//  CUBE
//
//  Created by matthew on 2019/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLProtocol(WQAAdd)
+ (void)wk_registerScheme:(NSString*)scheme;

+ (void)wk_unregisterScheme:(NSString*)scheme;
@end

NS_ASSUME_NONNULL_END
