//
//  CCOStreamDecoder.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/8/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>

@protocol CCIStreamDecoderDisplayDelegate <NSObject>

- (void)displayFrame:(CVImageBufferRef) frame;
- (void)closedStream;
@end

@interface CCIStreamDecoder : NSObject
//@property (weak) ViewController * delegate;
@property (assign) id <CCIStreamDecoderDisplayDelegate> outputDelegate;
@property (nonatomic, assign) CMVideoFormatDescriptionRef formatDesc;
@property (nonatomic, assign) VTDecompressionSessionRef decompressionSession;
@property (nonatomic, retain) AVSampleBufferDisplayLayer *videoLayer;
@property (nonatomic, assign) int spsSize;
@property (nonatomic, assign) int ppsSize;

- (id)initWithDelegate:(id <CCIStreamDecoderDisplayDelegate>) delegate;
-(void) receivedRawVideoFrame:(uint8_t *)frame withSize:(uint32_t)frameSize isIFrame:(int)isIFrame;
-(void) screenshotOfVideoStream:(CVImageBufferRef)imageBuffer;
@end
