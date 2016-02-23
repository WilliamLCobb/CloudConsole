//
//  CCOAppleEncoder.h
//  CloudConsole
//
//  Created by Will Cobb on 1/10/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
//  

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
@class CCOVideoStream;
@interface CCOh264Encoder : NSObject

@property (weak) CCOVideoStream     *streamController;

@property (assign, nonatomic) int32_t fps;
@property (assign, nonatomic) int32_t bitrate;

- (void)setFps:(int32_t)fps;
- (id)initWithController:(CCOVideoStream *)controller ScreenSize:(CGSize) screenSize;
- (BOOL)encodeFrame:(CGImageRef) captureImage frameNumber:(NSInteger) frameNumber;
- (void)stop;
@end
