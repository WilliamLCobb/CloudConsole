//
//  AudioClient.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/21/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#define kOutputBus 0
#define kInputBus 1
#import "AudioClient.h"
//#import "SM_Utils.h"
#include <AudioToolbox/AudioServices.h>
#include <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
@implementation AudioClient

static OSStatus OutputRenderCallback(void                        *inRefCon,
                                     AudioUnitRenderActionFlags  *ioActionFlags,
                                     const AudioTimeStamp        *inTimeStamp,
                                     UInt32                      inBusNumber,
                                     UInt32                      inNumberFrames,
                                     AudioBufferList             *ioData){
    
    AudioClient *output = (__bridge AudioClient*)inRefCon;
    
    
    TPCircularBuffer *circularBuffer = [output outputShouldUseCircularBuffer];
    if( !circularBuffer ){
        AudioUnitSampleType *left  = (AudioUnitSampleType*)ioData->mBuffers[0].mData;
        for(int i = 0; i < inNumberFrames; i++ ){
            left[ i ] = 0.0f;
        }
        return noErr;
    };
    
    int32_t bytesToCopy = ioData->mBuffers[0].mDataByteSize; //~1800
    SInt16* outputBuffer = ioData->mBuffers[0].mData;
    
    int32_t availableBytes;
    SInt16 *sourceBuffer = TPCircularBufferTail(circularBuffer, &availableBytes);
    
    int32_t amount = MIN(bytesToCopy,availableBytes);
    memcpy(outputBuffer, sourceBuffer, amount);
    
    TPCircularBufferConsume(circularBuffer,amount);
    
    return noErr;
}

-(id) initWithDelegate:(id)delegate
{
    if(!self)
    {
        self = [super init];
    }
    
    [self circularBuffer:&_circularBuffer withSize:24576*5];
    _delegate = delegate;
    stopped = NO;
    return self;
}

-(void) start
{
//    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue: dispatch_get_main_queue()];
//    
//    NSError *err;
//    
//    ipAddress = ip;
//    
//    [UIApplication sharedApplication].idleTimerDisabled = YES;
//    
//    if(![_socket connectToHost:ipAddress onPort:[SM_Utils serverPort] error:&err])
//    {
//        
//    }
    
    [self setupAudioUnit];
}


-(void) setupAudioUnit
{
    
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    
    OSStatus status;
    
    status = AudioComponentInstanceNew(comp, &_audioUnit);
    
    if(status != noErr)
    {
        NSLog(@"Error creating AudioUnit instance");
    }
    
    //  Enable input and output on AURemoteIO
    //  Input is enabled on the input scope of the input element
    //  Output is enabled on the output scope of the output element
    
    UInt32 one = 1;
    
    status = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, kOutputBus, &one, sizeof(one));
    
    if(status != noErr)
    {
        NSLog(@"Error enableling AudioUnit output bus");
    }
    
    
    AudioStreamBasicDescription audioFormat = [self getAudioDescription];
    
    status = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, kOutputBus, &audioFormat, sizeof(audioFormat));
    
    if(status != noErr)
    {
        NSLog(@"Error setting audio format");
    }
    
    AURenderCallbackStruct renderCallback;
    renderCallback.inputProc = OutputRenderCallback;
    renderCallback.inputProcRefCon = (__bridge void *)(self);
    
    status = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, kOutputBus, &renderCallback, sizeof(renderCallback));
    
    if(status != noErr)
    {
        NSLog(@"Error setting rendering callback");
    }
    
    // Initialize the AURemoteIO instance
    status = AudioUnitInitialize(_audioUnit);
    
    if(status != noErr)
    {
        NSLog(@"Error initializing audio unit");
    }
    
    status = AudioOutputUnitStart(_audioUnit);
    
    if(status != noErr)
    {
        NSLog(@"Error starting audio unit");
    }
}

- (AudioStreamBasicDescription)getAudioDescription {
    AudioStreamBasicDescription audioDescription = {0};
    audioDescription.mFormatID          = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags       = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian;
    audioDescription.mChannelsPerFrame  = 2;
    audioDescription.mBytesPerPacket    = sizeof(SInt16)*audioDescription.mChannelsPerFrame;
    audioDescription.mFramesPerPacket   = 1;
    audioDescription.mBytesPerFrame     = sizeof(SInt16)*audioDescription.mChannelsPerFrame;
    audioDescription.mBitsPerChannel    = 8 * sizeof(SInt16);
    audioDescription.mSampleRate        = 44100.0;
    return audioDescription;
}

-(void)parseData:(NSData *)data
{
    if(data.length > 0)
    {
        unsigned long len = [data length];
        
        SInt16* byteData = (SInt16*)malloc(len);
        memcpy(byteData, [data bytes], len);
        
//        double sum = 0.0;
//        for(int i = 0; i < len/2; i++) {
//            sum += byteData[i] * byteData[i];
//        }
//        
//        double average = sum / len;
//        double rms = sqrt(average);
        
        //[_delegate animateSoundIndicator:rms];
        
        Byte* soundData = (Byte*)malloc(len);
        memcpy(soundData, [data bytes], len);
        
        if(soundData)
        {
            AudioBufferList *theDataBuffer = (AudioBufferList*) malloc(sizeof(AudioBufferList) *1);
            theDataBuffer->mNumberBuffers = 1;
            theDataBuffer->mBuffers[0].mDataByteSize = (UInt32)len;
            theDataBuffer->mBuffers[0].mNumberChannels = 2;
            theDataBuffer->mBuffers[0].mData = (SInt16*)soundData;
            
            [self appendDataToCircularBuffer:&_circularBuffer fromAudioBufferList:theDataBuffer];
        }
    }
}

-(void)circularBuffer:(TPCircularBuffer *)circularBuffer withSize:(int)size {
    TPCircularBufferInit(circularBuffer,size);
}

-(void)appendDataToCircularBuffer:(TPCircularBuffer*)circularBuffer
              fromAudioBufferList:(AudioBufferList*)audioBufferList {
    TPCircularBufferProduceBytes(circularBuffer,
                                 audioBufferList->mBuffers[0].mData,
                                 audioBufferList->mBuffers[0].mDataByteSize);
}

-(void)freeCircularBuffer:(TPCircularBuffer *)circularBuffer {
    TPCircularBufferClear(circularBuffer);
    TPCircularBufferCleanup(circularBuffer);
}


-(TPCircularBuffer *) outputShouldUseCircularBuffer
{
    return &_circularBuffer;
}

-(void) stop
{
    
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    
    if(status != noErr)
    {
        NSLog(@"Error stopping audio unit");
    }
    
    
    TPCircularBufferClear(&_circularBuffer);
    _audioUnit = nil;
    stopped = YES;
}

-(void) dealloc {
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    
    if(status != noErr)
    {
        NSLog(@"Error stopping audio unit");
    }
    
    TPCircularBufferClear(&_circularBuffer);
    _audioUnit = nil;
    stopped = YES;
}

@end
