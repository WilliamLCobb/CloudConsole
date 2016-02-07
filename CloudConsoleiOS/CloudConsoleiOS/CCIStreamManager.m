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
                [streamDecoder receivedRawVideoFrame:data.bytes withSize:data.length];
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
    NSLog(@"Socket Disconnected: %@", error);
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
    [self.outputDelegate closedStream];
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
    [self.streamSocket sendData:directionalData withTimeout:10 CCtag:CCNetworkDirectionalState];
}

- (void)sendButtonState:(uint32_t)buttonState
{
    [self.streamSocket sendData:[NSData dataWithBytes:&buttonState length:4] withTimeout:10 CCtag:CCNetworkButtonState];
}


@end
