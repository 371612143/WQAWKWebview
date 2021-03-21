//
//  BGWeakProxy.h
//  appsdk
//
//  Created by Chia on 28/06/2017.
//

#import <Foundation/Foundation.h>

// copy from YYWeakProxy

NS_ASSUME_NONNULL_BEGIN

@interface BGWeakProxy : NSProxy

@property (nullable, nonatomic, weak, readonly) id target;

+ (instancetype)proxyWithTarget:(id)target;
- (instancetype)initWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
