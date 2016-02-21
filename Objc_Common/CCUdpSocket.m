//
//  CCUdpSocket.m
//  CloudConsole
//
//  Created by Will Cobb on 1/13/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
// http://www.gdcvault.com/play/1014345/I-Shot-You-First-Networking
#import "CCUdpSocket.h"
#import <QuartzCore/QuartzCore.h> //For CACurrentMediaTime

@interface GCDAsyncUdpSocket ()

- (void)notifyDidReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)context;
- (void)notifyDidConnectToAddress:(NSData *)anAddress;
- (void)notifyDidCloseWithError:(NSError *)error;
- (void)notifyDidSendDataWithTag:(long)tag;
@end

@interface CCUdpSocket () {
    dispatch_queue_t socketQueue;
    NSString    *host;
    uint16_t    port;
    CFTimeInterval  lastKeepAlive;
    BOOL        sendingKeepAlives;
    uint16_t    boundPort;
    NSInteger   timeout;
    
    int         wrongStateCount;
    NSMutableDictionary *buffers;
    
}

@end

@implementation CCUdpSocket

- (id)initWithDelegate:(id <CCUdpSocketDelegate>)aDelegate delegateQueue:(dispatch_queue_t)dq
{
    socketQueue = dispatch_queue_create([GCDAsyncUdpSocketQueueName UTF8String], NULL);
    if (self = [super initWithDelegate:aDelegate delegateQueue:dq socketQueue:socketQueue]) {
        lastKeepAlive = 0;
        wrongStateCount = 0;
        self.applicationState = CCStateHome;
        buffers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setDestinationHost:(NSString *)aHost port:(uint16_t)aPort
{
    host = aHost;
    port = aPort;
    [self reset];
}

- (void)reset
{
    wrongStateCount = 0;
    timeout = 20;
    lastKeepAlive = CACurrentMediaTime();
    [self startSendingKeepAlives];
}

- (void)close
{
    host = nil;
    port = 0;
    sendingKeepAlives = NO;
    lastKeepAlive = 0;
    [super close];
}

- (void)sendData:(NSData *)data
{
    [super sendData:data toHost:host port:port withTimeout:timeout tag:0];
    
    //Watch for changes
    if (self.localPort != 0 && self.localPort != boundPort) {
        NSError *err;
        [self beginReceiving:&err];
        if (err) {
            NSLog(@"Couldn't begin receiving: %@", err);
        }
        boundPort = self.localPort;
    }
}

- (void)sendData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
    NSLog(@"Error, using wrong send");
    //crash
    int *x;
    *x = 42;
}

- (void)sendData:(NSData *)data usingMethod:(CCUdpSendMethod)method CCtag:(uint32_t)tag
{
    if (!self.connected) {
        NSLog(@"Sending data to non-connected socket");
        //Maybe notify did not send data
        return;
    }
    [self sendData:data toHost:host port:port usingMethod:method CCtag:tag];
}

- (void)sendData:(NSData *)data toHost:(NSString *)ahost port:(uint16_t)aport usingMethod:(CCUdpSendMethod)method CCtag:(uint32_t)tag
{
    NSString *tagString = [NSString stringWithFormat:@"%u", tag];
    CCUdpBuffer *buffer = buffers[tagString];
    if (!buffer) {
        buffer = [[CCUdpBuffer alloc] initWithTag:tag delegate:self];
        [buffers setObject:buffer forKey:tagString];
    }
    [buffer queueDataForSending:data withMethod:method];
}

- (void)notifyDidSendDataWithTag:(long)tag
{
    [super notifyDidSendDataWithTag:tag];
}

- (BOOL)connected
{
    if (CACurrentMediaTime() - lastKeepAlive > timeout) {
        NSLog(@"Udp Socket Disconnected");
        [self notifyDidTimeout];
        return NO;
    }
    return YES;
}

- (void)startSendingKeepAlives
{
    if (!self.connected || sendingKeepAlives) {
        return;
    }
    sendingKeepAlives = YES;
    [self sendKeepAlives];
}

- (void)sendKeepAlives
{
    //NSLog(@"Sending Keep Alive");
    if (host.length != 0) {
        uint32_t keepAlive[2] = {CCNetworkStreamKeepAlive, self.applicationState};
        [self sendData:[NSData dataWithBytes:keepAlive length:8]];
    }
    if (!self.connected) {
        NSLog(@"Stopping keep alive 1");
        sendingKeepAlives = NO;
        return;
    }
    __weak id weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf sendKeepAlives];
    });
}

- (void)pingHost:(NSString *)aHost port:(uint16_t)aPort
{
    uint32_t ping[] = {CCNetworkPing, CCNetworkStreamBeginBlock, 0};
    [super sendData:[NSData dataWithBytes:ping length:12] toHost:aHost port:aPort withTimeout:-1 tag:0];
    [self beginReceiving:nil];
}

- (void)respondToPingAtHost:(NSString *)aHost port:(uint16_t)aPort withData:(NSData *)data
{
    uint32_t ping[] = {CCNetworkPingResponse, CCNetworkStreamBeginBlock, (uint32_t)data.length};
    NSMutableData *response = [NSMutableData dataWithBytes:ping length:12];
    [response appendData:data];
    [super sendData:response toHost:aHost port:aPort withTimeout:-1 tag:0];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Delegate Helpers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)notifyDidReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)context
{
    lastKeepAlive = CACurrentMediaTime();
    dispatch_async(self.delegateQueue, ^{
        uint32_t *message = (uint32_t*)data.bytes;
        uint32_t tag = message[0];
        switch (tag) {
            case CCNetworkStreamKeepAlive: {
                //NSLog(@"Got keep alive");
                if (message[1] != self.applicationState) {
                    wrongStateCount++;
                    if (wrongStateCount == 3) {
                        NSLog(@"Warning, socket is in a different state");
                        NSLog(@"Me: %u them: %u", self.applicationState, message[1]);
                        [self.delegate performSelectorOnMainThread:@selector(wrongApplicationState) withObject:nil waitUntilDone:NO];
                    }
                } else {
                    wrongStateCount = 0;
                    timeout = 5;
                }
                break;
            }
            case CCNetworkConnect: {
                if (self.connected) {
                    NSLog(@"CCudpSocket: Warning, connecting to new host but still connected to old");
                }
                [self setDestinationHost:[GCDAsyncSocket hostFromAddress:address] port:[GCDAsyncSocket portFromAddress:address]];
                [self notifyDidConnectToAddress:address];
                break;
            }
            default: {
                NSString *tagString = [NSString stringWithFormat:@"%u", tag];
                if (!buffers[tagString]) {
                    [buffers setObject:[[CCUdpBuffer alloc] initWithTag:tag delegate:self] forKey:tagString];
                }
                CCUdpBuffer *buffer = buffers[tagString];
                NSData *bufferData = [buffer consumeData:[NSData dataWithBytesNoCopy:(uint8_t*)data.bytes+4 length:data.length-4 freeWhenDone:NO]];
                if (bufferData) {
                    [self notifyDidReceiveData:bufferData fromAddress:address withTag:tag];
                }
                break;
            }
        }
        
        //Server socket changed port
        if ([host isEqualToString:[GCDAsyncSocket hostFromAddress:address]] && port != [GCDAsyncSocket portFromAddress:address] && tag != CCNetworkPing) {
            NSLog(@"Changing Socket port to: %d", [GCDAsyncSocket portFromAddress:address]);
            [self setDestinationHost:[GCDAsyncSocket hostFromAddress:address] port:[GCDAsyncSocket portFromAddress:address]];
        }
    });
}

- (void)notifyDidReceiveData:(NSData *)data fromAddress:(NSData *)address withTag:(uint32_t)tag
{
    SEL selector = @selector(CCSocket:didReceiveData:fromAddress:withTag:);
    
    if (self.delegateQueue && [self.delegate respondsToSelector:selector])
    {
        id theDelegate = self.delegate;
        dispatch_async(self.delegateQueue, ^{
            [theDelegate CCSocket:self didReceiveData:data fromAddress:address withTag:tag];
        });
    } else {
        NSLog(@"Warining, CCUdpSocket not notifying receive");
    }
}

- (void)notifyDidTimeout
{
    SEL selector = @selector(CCSocketTimedOut);
    
    //if (self.delegateQueue && [self.delegate respondsToSelector:selector])
    //{
        id theDelegate = self.delegate;
        dispatch_async(self.delegateQueue, ^{
            [theDelegate CCSocketTimedOut];
        });
    // }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Buffer Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)receiveProgress:(float)progress forTag:(uint32_t)tag
{
    SEL selector = @selector(CCSocket:downloadProgress:forTag:);
    
    if (self.delegateQueue && [self.delegate respondsToSelector:selector])
    {
        id theDelegate = self.delegate;
        dispatch_async(self.delegateQueue, ^{
            [theDelegate CCSocket:self downloadProgress:progress forTag:tag];
        });
    }
}

@end


