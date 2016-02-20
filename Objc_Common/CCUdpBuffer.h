//
//  CCUdpBuffer.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/23/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CCUdpSendMethod) {
    CCUdpSendMethodStream,
    CCUdpSendMethodRedundent,
    CCUdpSendMethodGuarentee
};

@protocol CCUdpBufferDelegate <NSObject>

- (void)sendData:(NSData *)data;
- (BOOL)connected;

@optional
- (void)receiveProgress:(float)progress forTag:(uint32_t)tag;

@end

@interface CCUdpBuffer : NSObject

@property (weak) id <CCUdpBufferDelegate> delegate;
@property uint32_t tag;

-(id)initWithTag:(uint32_t)tag delegate:(id <CCUdpBufferDelegate>)delegate;

- (void)queueDataForSending:(NSData *)data withMethod:(CCUdpSendMethod)method;
- (NSData *)consumeData:(NSData *)data;

@end
