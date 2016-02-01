//
//  CCUdpSocket.h
//  CloudConsole
//
//  Created by Will Cobb on 1/13/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <CocoaAsyncSocket/CocoaAsyncSocket.h>


@protocol CCUdpSocketDelegate <GCDAsyncUdpSocketDelegate>
- (void)wrongApplicationState;
@end

@interface CCUdpSocket : GCDAsyncUdpSocket


@property uint32_t applicationState;

- (void)setDestinationHost:(NSString *)aHost Port:(uint16_t)aPort;
- (void)sendData:(NSData *)data withTimeout:(NSTimeInterval)timeout CCtag:(uint32_t)tag;
- (void)reset;
- (BOOL)connected;
@end
