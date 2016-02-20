//
//  CCUdpSocket.h
//  CloudConsole
//
//  Created by Will Cobb on 1/13/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <CocoaAsyncSocket/CocoaAsyncSocket.h>
#import "CCUdpBuffer.h"
#import "CCNetworkProtocol.h"

@class CCUdpSocket;
@protocol CCUdpSocketDelegate <GCDAsyncUdpSocketDelegate>
- (void)CCSocket:(CCUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withTag:(uint32_t)tag;

@optional
- (void)CCSocket:(CCUdpSocket *)sock downloadProgress:(float)progress forTag:(uint32_t)tag;
- (void)wrongApplicationState;
- (void)CCSocketTimedOut;
@end

@interface CCUdpSocket : GCDAsyncUdpSocket <CCUdpBufferDelegate>


@property uint32_t applicationState;

- (void)setDestinationHost:(NSString *)aHost port:(uint16_t)aPort;
- (void)sendData:(NSData *)data usingMethod:(CCUdpSendMethod)method CCtag:(uint32_t)tag;
- (void)sendData:(NSData *)data toHost:(NSString *)host port:(uint16_t)port usingMethod:(CCUdpSendMethod)method CCtag:(uint32_t)tag;
- (void)pingHost:(NSString *)aHost port:(uint16_t)aPort;
- (void)respondToPingAtHost:(NSString *)aHost port:(uint16_t)aPort withData:(NSData *)data;
- (void)reset;
- (void)close;
- (BOOL)connected;
@end
