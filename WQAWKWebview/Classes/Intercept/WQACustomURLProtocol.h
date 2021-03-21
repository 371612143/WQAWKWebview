//
//  WQACustomURLProtocol.h
//  CUBE
//
//  Created by matthew on 2019/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** NSURLProtocol client action */
typedef NS_ENUM(NSUInteger, WQAURLProtocolAction) {
    
    WQAURLProtocolActionLoadData,
    
    WQAURLProtocolActionRecvResponse,
    
    WQAURLProtocolActionDidSuccess,
    
    WQAURLProtocolActionDidFaild,
};

@interface WQACustomURLProtocol : NSURLProtocol

@end

NS_ASSUME_NONNULL_END
