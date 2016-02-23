//
//  CCOStreamDecoder.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/8/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
//  http://stackoverflow.com/questions/24884827/possible-locations-for-sequence-picture-parameter-sets-for-h-264-stream/24890903#24890903
//  http://stackoverflow.com/questions/29525000/how-to-use-videotoolbox-to-decompress-h-264-video-stream
//  https://tools.ietf.org/html/rfc3984 extensive h264 documenatation

// Currently decodes 264 with hardware acceleration

#import "CCIStreamDecoder.h"
#import "AppDelegate.h"


@interface CCIStreamDecoder () {
    uint8_t *pps;
    uint8_t *sps;
    uint32_t spsSize;
    uint32_t ppsSize;
    
    CMBlockBufferRef blockBuffer;
    
    BOOL decodeErrorShown;
}

@end

@implementation CCIStreamDecoder

NSString * const naluTypesStrings[] =
{
    @"0: Unspecified (non-VCL)",
    @"1: Coded slice of a non-IDR picture (VCL)",    // P frame
    @"2: Coded slice data partition A (VCL)",
    @"3: Coded slice data partition B (VCL)",
    @"4: Coded slice data partition C (VCL)",
    @"5: Coded slice of an IDR picture (VCL)",      // I frame
    @"6: Supplemental enhancement information (SEI) (non-VCL)",
    @"7: Sequence parameter set (non-VCL)",         // SPS parameter
    @"8: Picture parameter set (non-VCL)",          // PPS parameter
    @"9: Access unit delimiter (non-VCL)",
    @"10: End of sequence (non-VCL)",
    @"11: End of stream (non-VCL)",
    @"12: Filler data (non-VCL)",
    @"13: Sequence parameter set extension (non-VCL)",
    @"14: Prefix NAL unit (non-VCL)",
    @"15: Subset sequence parameter set (non-VCL)",
    @"16: Reserved (non-VCL)",
    @"17: Reserved (non-VCL)",
    @"18: Reserved (non-VCL)",
    @"19: Coded slice of an auxiliary cod`ed picture without partitioning (non-VCL)",
    @"20: Coded slice extension (non-VCL)",
    @"21: Coded slice extension for depth view components (non-VCL)",
    @"22: Reserved (non-VCL)",
    @"23: Reserved (non-VCL)",
    @"24: STAP-A Single-time aggregation packet (non-VCL)",
    @"25: STAP-B Single-time aggregation packet (non-VCL)",
    @"26: MTAP16 Multi-time aggregation packet (non-VCL)",
    @"27: MTAP24 Multi-time aggregation packet (non-VCL)",
    @"28: FU-A Fragmentation unit (non-VCL)",
    @"29: FU-B Fragmentation unit (non-VCL)",
    @"30: Unspecified (non-VCL)",
    @"31: Unspecified (non-VCL)",
};

- (id)init {
    if (self = [super init]) {
    }
    return self;
}

- (uint32_t)nextFrameOffset:(uint8_t *)frame remainingSize:(uint32_t)size
{
    for (uint32_t i = 4; i < size; i+=1)
    {
        if (frame[i] == 0x00 && frame[i+1] == 0x00 && frame[i+2] == 0x00 && frame[i+3] == 0x01)
        {
            return i;
        }
    }
    return 0;
}

-(void) receivedRawVideoFrame:(uint8_t *)frame withSize:(uint32_t)frameSize
{
    int naluType = 0;
    uint32_t offset = 0;//[self nextFrameOffset:frame remainingSize:frameSize];
    BOOL shouldDecode = NO; //If we shoudl encode at the end of the data
    while (offset < frameSize) {
        uint8_t * blockStart = &frame[offset];
        naluType = (blockStart[4] & 0x1F);
        if (naluType == 1 && _formatDesc) {
            shouldDecode = YES;
            uint32_t nextOffset = [self nextFrameOffset:blockStart remainingSize:frameSize - offset];
            if (!nextOffset) { //Last NALU
                [self storeNonIDRFrame:blockStart size:frameSize - offset];
                break;
            } else { //Just a piece
                [self storeNonIDRFrame:blockStart size:nextOffset];
            }
            offset += nextOffset;
        } else if (naluType == 5 && _formatDesc) {
            shouldDecode = YES;
            uint32_t nextOffset = [self nextFrameOffset:blockStart remainingSize:frameSize - offset];
            if (!nextOffset) { //Last NALU
                [self storeIDRFrame:blockStart size:frameSize - offset];
                break;
            } else { //Just a piece
                [self storeIDRFrame:blockStart size:nextOffset];
            }
            offset += nextOffset;
        } else if (naluType == 7) {
            uint32_t nextOffset = [self nextFrameOffset:blockStart remainingSize:frameSize - offset];
            spsSize = [self storeSPS:blockStart size:nextOffset];
            offset += nextOffset;
        } else if (naluType == 8) {
            uint32_t nextOffset = [self nextFrameOffset:blockStart remainingSize:frameSize - offset];
            ppsSize = [self storePPS:blockStart size:nextOffset];
            offset += nextOffset;
            if (_decompressionSession == NULL) { //Should make sure everything is okay at this point
                [self updateStreamSettings]; // Maybe move this out of if
                [self createDecompSession];
            }
        } else {
            if (naluType != 6) {
                NSLog(@"Error unknown NALU: %d", naluType);
                return;
            }
            uint32_t nextOffset = [self nextFrameOffset:blockStart remainingSize:frameSize - offset];
            if (!nextOffset)
                return;
            offset += nextOffset;
        }
    }
    if (shouldDecode) {
        [self decodeBlock];
        blockBuffer = NULL;
    }
    
}

- (uint32_t)storeSPS:(uint8_t *)block size:(uint32_t)size{
    sps = malloc(size - 4); //dont keep start code
    memcpy(sps, &block[4], size);
    return size - 4;
}

- (uint32_t)storePPS:(uint8_t *)block size:(uint32_t)size{
    pps = malloc(size - 4); //dont keep start code
    memcpy(pps, &block[4], size);
    return size - 4;
}

- (void)updateStreamSettings {
    uint8_t* parameterSetPointers[2] = {sps, pps};
    size_t parameterSetSizes[2] = {spsSize, ppsSize};
    
    NSLog(@"Updated stream settings");
    
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2,
                                                                          (const uint8_t *const*)parameterSetPointers,
                                                                          parameterSetSizes, 4,
                                                                          &_formatDesc);
    
    if(status != noErr) NSLog(@"\t\t Format Description ERROR type: %d", (int)status);
}

- (BOOL)storeIDRFrame:(uint8_t *)block size:(uint32_t)size
{
    // create or copy a block buffer from the IDR NALU
    OSStatus status;
    if (!blockBuffer) {
        uint8_t *data = malloc(size);
        memcpy(data, block, size);
        //Convert Anex B to AVCC: http://aviadr1.blogspot.com/2010/05/h264-extradata-partially-explained-for.html
        uint32_t dataLength32 = htonl(size - 4);
        memcpy(data, &dataLength32, 4);
        status = CMBlockBufferCreateWithMemoryBlock(NULL, data,  // memoryBlock to hold buffered data
                                                         size,  // block length of the mem block in bytes.
                                                         kCFAllocatorDefault, NULL,
                                                         0, // offsetToData
                                                         size,   // dataLength of relevant bytes, starting at offsetToData
                                                         0,
                                                         &blockBuffer);
    } else {
        uint8_t *data = malloc(size);
        memcpy(data, block, size);
        
        uint32_t dataLength32 = htonl(size - 4);
        memcpy(data, &dataLength32, 4);
        status = CMBlockBufferAppendMemoryBlock(blockBuffer, data, size, kCFAllocatorDefault, NULL, 0, size, 0);
    }
    
    //NSLog(@"IDR Frame Creation: \t %@", (status == kCMBlockBufferNoErr) ? @"successful!" : @"failed...");
    if (status != kCMBlockBufferNoErr) {
        NSLog(@"Error: %d", status);
    }
    //free(data);
    return status == kCMBlockBufferNoErr;
}

- (BOOL)storeNonIDRFrame:(uint8_t *)block size:(uint32_t)size
{
    return [self storeIDRFrame:block size:size];
//    OSStatus status;
//    if (!blockBuffer) {
//        uint8_t *data = malloc(size);
//        memcpy(data, block, size);
//        uint32_t dataLength32 = htonl(size - 4);
//        memcpy(data, &dataLength32, 4);
//        status = CMBlockBufferCreateWithMemoryBlock(NULL, data,  // memoryBlock to hold buffered data
//                                                    size,  // block length of the mem block in bytes.
//                                                    kCFAllocatorDefault, NULL,
//                                                    0, // offsetToData
//                                                    size,   // dataLength of relevant bytes, starting at offsetToData
//                                                    0,
//                                                    &blockBuffer);
//    } else {
//        uint8_t *data = malloc(size);
//        memcpy(data, block, size);
//        
//        uint32_t dataLength32 = htonl(size - 4);
//        memcpy(data, &dataLength32, 4);
//        status = CMBlockBufferAppendMemoryBlock(blockBuffer, data, size, kCFAllocatorDefault, NULL, 0, size, 0);
//    }
//    
//    //NSLog(@"Non IDR Frame Creation: \t %@", (status == kCMBlockBufferNoErr) ? @"successful!" : @"failed...");
//    if (status != kCMBlockBufferNoErr) {
//        NSLog(@"Error: %d", status);
//    }
//    //free(data);
//    return status == kCMBlockBufferNoErr;
}

- (void)decodeBlock
{
    const size_t sampleSize = CMBlockBufferGetDataLength(blockBuffer);
    // Overide the first 4 bytes to indicate buffer size
    //uint32_t dataLength32 = htonl(sampleSize - 4);
    //CMBlockBufferReplaceDataBytes(&dataLength32, blockBuffer, 0, 4);
    
    
    CMSampleBufferRef sampleBuffer = NULL;
    OSStatus status = CMSampleBufferCreate(kCFAllocatorDefault,
                                           blockBuffer, true, NULL, NULL,
                                           _formatDesc, 1, 0, NULL, 1,
                                           &sampleSize, &sampleBuffer);
    
    
    if (status != noErr) {
        NSLog(@"Unable to create sample buffer: %d", status);
        return;
    }
    
    // set some values of the sample buffer's attachments
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    
    // either send the samplebuffer to a VTDecompressionSession or to an AVSampleBufferDisplayLayer
    VTDecodeInfoFlags flagOut;
    VTDecompressionSessionDecodeFrame(_decompressionSession, sampleBuffer, kVTDecodeFrame_EnableAsynchronousDecompression, NULL, &flagOut);
    
    //[self render:sampleBuffer];
}

-(void) createDecompSession
{
    NSLog(@"Creating Session!");
    // make sure to destroy the old VTD session
    _decompressionSession = NULL;
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = decompressionSessionDecodeFrameCallback;
    callBackRecord.decompressionOutputRefCon = (__bridge void *)self.outputDelegate;
    
    NSDictionary *destinationImageBufferAttributes = @{(id)kCVPixelBufferOpenGLESCompatibilityKey: [NSNumber numberWithBool:YES],
                                                       (id)kVTDecompressionPropertyKey_RealTime: [NSNumber numberWithBool:YES]};
    
    OSStatus status =  VTDecompressionSessionCreate(NULL, _formatDesc, NULL,
                                                    (__bridge CFDictionaryRef)(destinationImageBufferAttributes),
                                                    &callBackRecord, &_decompressionSession);
    if (status != noErr) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error creating session!!! Bad: %@", error);
        if (status == -12911 && !decodeErrorShown) {
            decodeErrorShown = YES;
            [AppDelegate.sharedInstance showError:@"The hardware video decoder in your iPhone is malfunctioning. I don't really know what causes this and the only way I know to fix this is to restart your phone. If this message does not go away, please tell me" withTitle:@"Device Malfunction"];
            //[self.outputDelegate closedStream];
        }
    }
}

void decompressionSessionDecodeFrameCallback(void *decompressionOutputRefCon,
                                             void *sourceFrameRefCon,
                                             OSStatus status,
                                             VTDecodeInfoFlags infoFlags,
                                             CVImageBufferRef imageBuffer,
                                             CMTime presentationTimeStamp,
                                             CMTime presentationDuration)
{
    id <CCIStreamDecoderDisplayDelegate> streamDisplayer = (__bridge id)(decompressionOutputRefCon);
    if (status != noErr) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Decompressed error: %@", error);
    } else {
        [streamDisplayer displayFrame:imageBuffer];
    }
}

- (void)dealloc
{
    NSLog(@"Deallocating decoder");
    VTDecompressionSessionInvalidate(_decompressionSession);
}

@end
