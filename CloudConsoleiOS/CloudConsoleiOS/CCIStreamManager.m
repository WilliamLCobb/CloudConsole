//
//  CCIStreamManager.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/11/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIStreamManager.h"
#import "CCNetworkProtocol.h"
#import "AudioClient.h"
#import "AppDelegate.h"

@interface CCIStreamManager () {
    CCIStreamDecoder    *streamDecoder;
    BOOL                streaming;
    
    //Recieve Information
    NSData          *senderAddress;
    
    AudioClient     *audioClient;
    
    dispatch_queue_t videoDecodeQueue;
    dispatch_queue_t audioDecodeQueue;
    
    NSMutableArray  *frameQueue;
    
}

@end

@implementation CCIStreamManager

- (id)init {
    if (self = [super init]) {
        streamDecoder = [[CCIStreamDecoder alloc] init];
        videoDecodeQueue = dispatch_queue_create("Video Decode Queue", NULL);
        
        audioClient = [[AudioClient alloc] initWithDelegate:self];
        [audioClient start];
        audioDecodeQueue = dispatch_queue_create("Audio Decode Queue", NULL);
        
        frameQueue = [NSMutableArray array];
    }
    return self;
}

//Video Output
- (void) setOutputDelegate:(id <CCIStreamDecoderDisplayDelegate>) delegate
{
    NSLog(@"Set Output Delegate");
    _outputDelegate = delegate;
    streamDecoder.outputDelegate = delegate;
}

- (void)CCSocket:(CCUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withTag:(uint32_t)tag
{
    //NSLog(@"Recieved Data From: %@, %ld", address, data.length);
    //uint32_t *frameData = (uint32_t*)data.bytes;
    senderAddress = address;
    switch (tag) {
        case CCNetworkVideoData:
        {
            // Lag detection
            static CFTimeInterval now = 0;
            float fps = 1/(CACurrentMediaTime() - now);
            if (fps < 10) {
                NSLog(@"Network lag: %d, %f", (int)fps, CACurrentMediaTime() - now);
            }
            now = CACurrentMediaTime();
            ///
            dispatch_async(videoDecodeQueue, ^{
                [streamDecoder receivedRawVideoFrame:(void *)data.bytes withSize:(uint32_t)data.length];
            });
            
            break;
        }
        case CCNetworkAudioData:
        {
            dispatch_async(audioDecodeQueue, ^{
                [audioClient parseData:data];
            });
            break;
        }
        default:
            break;
    }
}


- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    NSLog(@"Warning!!! Socket Disconnected: %@", error);
}

- (void)CCSocketTimedOut
{
    NSLog(@"Socket timed out");
    if (streamDecoder) { //first call
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AppDelegate.sharedInstance showWarning:@"Lost connection to the server" withTitle:@"Disconnected"];
        });
    }
    [self streamClosed];
}

- (void)closeStream
{
    //Should send someting here to server and display a notice to the user
    [self streamClosed];
}

- (void)streamClosed
{
    NSLog(@"Stream Closed");
    if (self.outputDelegate && [self.outputDelegate respondsToSelector:@selector(closedStream)]) {
        [self.outputDelegate closedStream];
    }
    [self.delegate streamClosed];
    self.streamSocket.applicationState = CCStateHome;
    [audioClient stop];
    streamDecoder = nil;
}

- (void)wrongApplicationState
{
    NSLog(@"Wrong Application State stream manager");
    [self streamClosed];
}

#pragma mark - Controls

- (void)sendDirectionalState:(CGPoint)directionalState forJoy:(uint8_t)joyId
{
    int8_t data[3] = {joyId, (int8_t)(directionalState.x * 127), (int8_t)(directionalState.y * 127)};
    NSMutableData * directionalData = [NSMutableData data];
    [directionalData appendBytes:data length:3];
    [self.streamSocket sendData:directionalData usingMethod:CCUdpSendMethodRedundent CCtag:CCNetworkDirectionalState];
}

- (void)sendButtonState:(uint32_t)buttonState
{
    [self.streamSocket sendData:[NSData dataWithBytes:&buttonState length:4] usingMethod:CCUdpSendMethodRedundent CCtag:CCNetworkButtonState];
}


@end
