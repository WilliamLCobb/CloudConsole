//
//  VideoStream.h
//  CloudConsole
//
//  Created by Will Cobb on 1/5/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"
#import "GCDAsyncSocket.h"
#import "CCOWindowCapture.h"
#import <AVFoundation/AVFoundation.h>

@class CCOServer;
@class CCUdpSocket;
@class CapturedFrameData;

@protocol CCVideoStreamDelegate <NSObject>
- (void)streamClosed;
@end

@interface CCOVideoStream : NSObject <CCOWindowCaptureDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (strong) NSString *host;
@property (assign) NSInteger port;
@property (assign) double   captureFPS;
@property id <CCVideoStreamDelegate> delegate;

- (id)initWithGamePid:(pid_t)pid delegate:(id <CCVideoStreamDelegate>)delegate;
- (BOOL)beginStreamWithSocket:(CCUdpSocket *) socket;
- (void)sendEncodedData:(NSData *)frameData type:(uint32_t)dataType;
- (CCUdpSocket *)streamSocket;
- (BOOL)encodeFrame;
- (double)mach_time_seconds;
@end
