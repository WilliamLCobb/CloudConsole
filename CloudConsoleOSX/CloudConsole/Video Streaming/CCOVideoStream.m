//
//  VideoStream.m
//  CloudConsole
//
//  Created by Will Cobb on 1/5/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

/// Video
//  http://dranger.com/ffmpeg/tutorial01.html
//  https://www.ffmpeg.org/doxygen/0.6/api-example_8c-source.html
//  https://gist.github.com/roxlu/5871639 //264

//  brew install ffmpeg --with-fdk-aac --with-ffplay --with-freetype --with-libass --with-libquvi --with-libvorbis --with-libvpx --with-opus --with-x265

//  https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_performance/ci_performance.html

//  http://stackoverflow.com/questions/9234724/how-to-change-hue-of-a-texture-with-glsl/9234854#9234854

//  https://codesequoia.wordpress.com/2009/10/18/h-264-stream-structure/ NAL

//  https://developer.apple.com/library/mac/documentation/Darwin/Conceptual/KEXTConcept/KEXTConceptIOKit/iokit_tutorial.html

/// Audio
//  http://stackoverflow.com/questions/19849509/encoding-pcm-cmsamplebufferref-to-aac-on-ios-how-to-set-frequency-and-bitrat
//  http://stackoverflow.com/questions/10817036/can-i-use-avcapturesession-to-encode-an-aac-stream-to-memory
//  http://technology.ezeenow.com/posts/2572/Playing_voice_from_server_stream_of_nsdata_using_AudioUnit_IOS
//  http://stackoverflow.com/questions/17957720/how-to-record-and-play-back-audio-in-real-time-on-os-x
//  http://stackoverflow.com/questions/31691361/output-is-not-generated-audioconverterfillcomplexbuffer-to-convert-from-aac-to-p
//  http://stackoverflow.com/questions/28340738/playing-raw-pcm-audio-data-coming-from-nsstream**
//  https://www.yotta.co.za/Blog/2015/5/19/playing-audio-on-ios-from-a-socket-connection **


#import "CCNetworkProtocol.h"

#import "CCOVideoStream.h"
#import "CCOServer.h"
#import "CCOh264Encoder.h"
#import "CCGamepadInput.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <libproc.h>

#include <CoreFoundation/CoreFoundation.h>
#include <Carbon/Carbon.h> /* For kVK_ constants, and TIS functions. */
#import <CoreAudio/CoreAudioTypes.h>

#import "AudioServer.h"
#import "CCUdpSocket.h"

@interface CCOVideoStream () <CCUdpSocketDelegate> {
    CCOWindowCapture    *windowCapture;
    CCUdpSocket         *streamSocket;
    CCOh264Encoder      *encoder;
    
    
    mach_timebase_info_data_t _mach_timebase;
    
    BOOL streaming;
    BOOL compressorSetUp;
    BOOL usingUDP;
    
    long long frameCount;
    
    CCGamepadInput      *controller;
    //Audio
    AudioServer         *audioServer;
}

@end

@implementation CCOVideoStream

- (id)initWithGamePid:(pid_t)pid delegate:(id<CCVideoStreamDelegate>)delegate
{
    if (self = [super init]) {
        windowCapture = [[CCOWindowCapture alloc] initWithPid:pid];
        if (!windowCapture) {
            NSLog(@"Unable to set up screen capture");
            return nil;
        }
        
        mach_timebase_info(&_mach_timebase);
        self.captureFPS = 30;
        self.delegate = delegate;
        
        encoder = [[CCOh264Encoder alloc] initWithController:self ScreenSize:[windowCapture windowSize]];
        encoder.fps = self.captureFPS;
        
        controller = [[CCGamepadInput alloc] init];
        
        ///Audio
        audioServer = [[AudioServer alloc] init];
        audioServer.delegate = self;
    }
    return self;
}

#pragma mark - Main Loop`

//Assume here the socket has been hole punched and we will be receiving on the sockets port
- (BOOL)beginStreamWithSocket:(CCUdpSocket *)socket
{
    NSLog(@"Beginning New Stream");
    socket.applicationState = CCStateInStream;
    [socket reset];
    streamSocket = socket;
    usingUDP = YES;
    streaming = YES;
    [self startMainLoop];
    [audioServer start];
    return YES;
}


- (CCUdpSocket *)streamSocket
{
    return streamSocket;
}

- (void)startMainLoop
{
    
    frameCount = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (streaming) {
            if (![self encodeFrame]) {
                NSLog(@"Encoding Error :(");
            } else {
                //NSLog(@"Encoding Success");
            }
            [self throttle];
        }
    });
}

- (void)closeStream
{
    NSLog(@"Closing Stream");
    streaming = NO;
    [encoder stop];
    encoder = nil;
    [audioServer stop];
    [self.delegate streamClosed];
    //Need to dealloc everything
}

- (void)throttle
{
    static CFTimeInterval startTime = 0;
    if (startTime == 0)
        startTime = CACurrentMediaTime();
    
    CFTimeInterval nextRunTime = startTime + (1.0/self.captureFPS);
    
    if (CACurrentMediaTime() - startTime > 1.3/self.captureFPS && self.captureFPS > 30) {
        self.captureFPS--;
        NSLog(@"Dropping FR to :%f", self.captureFPS);
    } else {
        double sleepTime = (1.0/self.captureFPS -  (CACurrentMediaTime() - startTime));
        if (sleepTime > 1.0/self.captureFPS) {
            //self.captureFPS++;
            NSLog(@"Increasing FR to :%f", self.captureFPS);
        }
        
        while (CACurrentMediaTime() - startTime < 1.0/self.captureFPS) {
            usleep(sleepTime * 1e6);
            sleepTime = (1.0/self.captureFPS - (CACurrentMediaTime() - startTime));
        }
    }
    startTime = nextRunTime;
    return;
}

#pragma mark - Window Capture Delegate

- (void)windowSizeChanged
{
    NSLog(@"Need to update window size");
}

- (void)windowClosed
{
    [self closeStream];
}

#pragma mark - Network

- (void)sendEncodedData:(NSData *)frameData type:(uint32_t)dataType
{
    [streamSocket sendData:frameData withTimeout:-1 CCtag:dataType];
}

- (void)CCSocket:(CCUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withTag:(uint32_t)tag
{
    uint32_t *message = (uint32_t*)data.bytes;
    switch (tag) {
        case CCNetworkDirectionalState:
        {
            int8_t *joyData = (int8_t *)data.bytes;
            [controller setJoy:joyData[0] X:joyData[1] Y:joyData[2]];
            break;
        }
        case CCNetworkButtonState:
            [controller setButtonState:(uint16_t)message[0]];
            break;
            
        default:
            break;
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    //NSLog(@"Sent stream data");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"Unable to send steam data with error: %@", error);
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    NSLog(@"Stream Socket closed... %@", error);
    //[self closeStream];
}

- (void)CCSocketTimedOut
{
    NSLog(@"Socket timed out");
    [self closeStream];
}

- (void)wrongApplicationState
{
    [self closeStream];
}

#pragma mark - Video

- (BOOL)encodeFrame //Will convert into coded data
{
    if (!streaming) return NO;
    //NSLog(@"New Frame");
    CGImageRef capImage = [windowCapture captureFrame];
    if (![encoder encodeFrame:capImage frameNumber:frameCount++]) {
        NSLog(@"Error encoding frame!");
        return NO;
    }
    CGImageRelease(capImage);
    return YES;
}

-(double)mach_time_seconds
{
    double retval;
    uint64_t mach_now = mach_absolute_time();
    retval = (double)((mach_now * _mach_timebase.numer / _mach_timebase.denom))/NSEC_PER_SEC;
    return retval;
}

@end
