//
//  CCOAppleEncoder.m
//  CloudConsole
//
//  Created by Will Cobb on 1/10/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
// https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.8.sdk/System/Library/Frameworks/VideoToolbox.framework/Versions/A/Headers/VTCompressionSession.h

#import "CCOh264Encoder.h"
#import "CCOVideoStream.h"
#import "CCNetworkProtocol.h"
@interface CCOh264Encoder() {
    VTCompressionSessionRef compressionSession;
}
@end;

@implementation CCOh264Encoder

- (id)initWithController:(CCOVideoStream *)controller ScreenSize:(CGSize) screenSize {
    if (self = [super init]) {
        self.streamController = controller;
        CFMutableDictionaryRef sessionAttributes = CFDictionaryCreateMutable(
                                                                             NULL,
                                                                             0,
                                                                             &kCFTypeDictionaryKeyCallBacks,
                                                                             &kCFTypeDictionaryValueCallBacks);
        
        CFDictionarySetValue(sessionAttributes, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_High_AutoLevel);
        CFDictionarySetValue(sessionAttributes,  kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder, kCFBooleanTrue);
        NSNumber *v = [NSNumber numberWithInt: 0];
        CFDictionarySetValue(sessionAttributes, kVTCompressionPropertyKey_MaxFrameDelayCount, (__bridge void *)v); //Doesn't work
    
        
        OSStatus err = VTCompressionSessionCreate(kCFAllocatorDefault,
                                                  MAX(screenSize.width, 50),
                                                  MAX(screenSize.height, 50),
                                                  kCMVideoCodecType_H264,
                                                  sessionAttributes,
                                                  NULL,
                                                  kCFAllocatorDefault,
                                                  vtCallback,
                                                  (__bridge void *)controller,
                                                  &compressionSession);
        
        
        
        if(err == noErr) {
            
            const int32_t v = self.fps * 2; // 2-second kfi seems to always be suggested
            
            CFNumberRef ref = CFNumberCreate(NULL, kCFNumberSInt32Type, &v);
            err = VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, ref);
            CFRelease(ref);
        } else {
            NSLog(@"Compression setup Error 1");
        }
        
        if(err == noErr) {
            const int32_t v = self.fps;
            CFNumberRef ref = CFNumberCreate(NULL, kCFNumberSInt32Type, &v);
            err = VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, ref);
            CFRelease(ref);
        } else {
            NSLog(@"Compression setup Error 2");
        }
        
        if(err == noErr) {
            err = VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
        } else {
            NSLog(@"Compression setup Error 3");
        }
        
//        if(err == noErr) {
//            err = VTSessionSetProperty(compressionSession , kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder, kCFBooleanFalse);
//        } else {
//            NSLog(@"Compression setup Error 4");
//        }
        
        if(err == noErr) {
            const int v = (8 * 1024) * 300; // KB/sec
            CFNumberRef ref = CFNumberCreate(NULL, kCFNumberSInt32Type, &v);
            err = VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, ref);
            if (err != noErr) NSLog(@"Setup Error: Average bitrate -> %d", err);
            CFRelease(ref);
        } else {
            NSLog(@"Compression setup Error 5");
        }
        
        if(err == noErr) {
            err = VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        } else {
            NSLog(@"Compression setup Error 6");
        }
        
        if(err == noErr) {
            err = VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CAVLC);
        } else {
            NSLog(@"Compression setup Error 7");
        }
        
        if(err == noErr) {
            NSLog(@"Encoder Set up successfully");
            VTCompressionSessionPrepareToEncodeFrames(compressionSession);
        } else {
            NSLog(@"Unable to set up encoding %d", err);
        }
    }
    return self;
}

- (BOOL)encodeFrame:(CGImageRef)captureImage frameNumber:(NSInteger)frameNumber
{
    if (!compressionSession) return NO;
    CVPixelBufferRef pixelBuffer = [self pixelBufferFromCGImage:captureImage];
    OSStatus status = VTCompressionSessionEncodeFrame(compressionSession, pixelBuffer, CMTimeMake(frameNumber, self.fps), CMTimeMake(1, self.fps), NULL, (__bridge void *)self, NULL);
    CVPixelBufferRelease(pixelBuffer);
    if (status != noErr) {
        NSLog(@"Error encoding frame: %d", status);
    }
    VTCompressionSessionCompleteFrames(compressionSession, CMTimeMake(frameNumber, self.fps));
    return status == noErr;
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image{
    
    CVPixelBufferRef pxbuffer = NULL;
    CFDictionaryRef options = (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                         [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                                         [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                                         nil];
    
    size_t width =  CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    size_t bytesPerRow = CGImageGetBytesPerRow(image);
    
    CFDataRef  dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(image));
    GLubyte  *imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
    
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault,width,height,kCVPixelFormatType_32BGRA,imageData,bytesPerRow,NULL,NULL,options,&pxbuffer);
    //CFRelease(options);
    CFRelease(dataFromImageDataProvider);
    return pxbuffer;
    
}

- (void)stop
{
    NSLog(@"Stopped compression");
    if (compressionSession) {
        VTCompressionSessionInvalidate(compressionSession);
        compressionSession = nil;
    }
}

//http://stackoverflow.com/questions/28396622/extracting-h264-from-cmblockbuffer
void vtCallback(void *outputCallbackRefCon,
                void *sourceFrameRefCon,
                OSStatus status,
                VTEncodeInfoFlags infoFlags,
                CMSampleBufferRef sampleBuffer )
{
    //NSLog(@"Got callback");
    CCOVideoStream *streamManager = (__bridge CCOVideoStream *)outputCallbackRefCon; //Change this to delegate later
    
    // Right now we've converting from AVCC to Anex B and on the client side we're converting back to AVCC
    // It might be possible to save some CPU time by skipping the conversion and adding our own custom headers
    // to packets
    
    
    // Check if there were any errors encoding
    if (status != noErr) {
        NSLog(@"Error encoding video, err=%lld", (int64_t)status);
        return;
    }
    
    NSMutableData *elementaryStream = [NSMutableData data];
    
    
    // Find out if the sample buffer contains an I-Frame.
    // If so we will write the SPS and PPS NAL units to the elementary stream.
    BOOL isIFrame = NO;
    CFArrayRef attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, 0);
    if (CFArrayGetCount(attachmentsArray)) {
        CFBooleanRef notSync;
        CFDictionaryRef dict = CFArrayGetValueAtIndex(attachmentsArray, 0);
        BOOL keyExists = CFDictionaryGetValueIfPresent(dict,
                                                       kCMSampleAttachmentKey_NotSync,
                                                       (const void **)&notSync);

        isIFrame = !keyExists || !CFBooleanGetValue(notSync);
        //CFRelease(dict);
    }

    static const size_t startCodeLength = 4;
    static const uint8_t startCode[] = {0x00, 0x00, 0x00, 0x01};
    
    // Write the SPS and PPS NAL units to the elementary stream before every I-Frame
    if (isIFrame) {
        CMFormatDescriptionRef description = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        // Find out how many parameter sets there are
        size_t numberOfParameterSets;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                           0, NULL, NULL,
                                                           &numberOfParameterSets,
                                                           NULL);
        
        // Write each parameter set to the elementary stream usually 2
        for (int i = 0; i < numberOfParameterSets; i++) {
            const uint8_t *parameterSetPointer;
            size_t parameterSetLength;
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                               i,
                                                               &parameterSetPointer,
                                                               &parameterSetLength,
                                                               NULL, NULL);
            
            [elementaryStream appendBytes:startCode length:startCodeLength];
            [elementaryStream appendBytes:parameterSetPointer length:parameterSetLength];
        }
    }
    
    // Get a pointer to the raw AVCC NAL unit data in the sample buffer
    size_t blockBufferLength;
    uint8_t *bufferDataPointer = NULL;
    CMBlockBufferGetDataPointer(CMSampleBufferGetDataBuffer(sampleBuffer),
                                0,
                                NULL,
                                &blockBufferLength,
                                (char **)&bufferDataPointer);
    
    // Loop through all the NAL units in the block buffer
    // and write them to the elementary stream with
    // start codes instead of AVCC length headers
    size_t bufferOffset = 0;
    static const int AVCCHeaderLength = 4;
    while (bufferOffset < blockBufferLength - AVCCHeaderLength) {
        // Read the NAL unit length
        uint32_t NALUnitLength = 0;
        memcpy(&NALUnitLength, bufferDataPointer + bufferOffset, AVCCHeaderLength);
        // Convert the length value from Big-endian to Little-endian
        NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
        // Write start code to the elementary stream
        [elementaryStream appendBytes:startCode length:startCodeLength];
        // Write the NAL unit without the AVCC length header to the elementary stream
        [elementaryStream appendBytes:bufferDataPointer + bufferOffset + AVCCHeaderLength
                               length:NALUnitLength];
        // Move to the next NAL unit in the block buffer
        bufferOffset += AVCCHeaderLength + NALUnitLength;
    }
    [streamManager sendEncodedData:elementaryStream type:CCNetworkVideoData];
}

- (void)dealloc
{
    [self stop];
}

@end
