//
//  AudioServer.m
//  CloudConsole
//
//  Created by Will Cobb on 1/21/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
//  https://www.yotta.co.za/blog/2015/5/19/playing-audio-on-ios-from-a-socket-connection

#import "CCNetworkProtocol.h"

#define kOutputBus 0
#define kInputBus 1

#import "AudioServer.h"
#import "AudioDevice.h"
#import "AudioDeviceList.h"
//#import "SM_Utils.h"

// https://github.com/alexbw/novocaine

static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    // TODO: Use inRefCon to access our interface object to do stuff
    // Then, use inNumberFrames to figure out how much data is available, and make
    // that much space available in buffers in an AudioBufferList.
    AudioServer *server = (__bridge AudioServer*)inRefCon;
    
    AudioBufferList bufferList;
    
    SInt16 samples[inNumberFrames]; // A large enough size to not have to worry about buffer overrun
    memset (&samples, 0, sizeof (samples));
    
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = samples;
    bufferList.mBuffers[0].mNumberChannels = 1;
    bufferList.mBuffers[0].mDataByteSize = inNumberFrames*sizeof(SInt16);
    
    // Then:
    // Obtain recorded samples
    
    OSStatus status;
    
    status = AudioUnitRender(server.audioUnit,
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
    
    NSData *dataToSend = [NSData dataWithBytes:bufferList.mBuffers[0].mData length:bufferList.mBuffers[0].mDataByteSize];
    [server.delegate sendEncodedData:dataToSend type:CCNetworkAudioData];
    NSLog(@"Sending: %@", dataToSend);
    return noErr;
}

@implementation AudioServer

-(id) init
{
    return [super init];
}

-(void) start
{
    NSLog(@"Audio Starting");
    // Create a new instance of AURemoteIO
    OSStatus err = noErr;
    
    
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_HALOutput;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    AudioComponentInstanceNew(comp, &_audioUnit);
    
    ///
    /*  Select Soundflower  */
    AudioDeviceID inputDeviceID;
    AudioDeviceList *mOutputDeviceList = new AudioDeviceList(true);
    //    //Sometimes selecting "Airplay" causes empty device list for a while and then
    //    //changes all DeviceID(CoreAudio Restarted??), In that case we need retart
    //    while(mOutputDeviceList->GetList().size() == 0){
    //        restartRequired = true;
    //        delete mOutputDeviceList;
    //        [NSThread sleepForTimeInterval:0.1];
    //        mOutputDeviceList = new AudioDeviceList(false);
    //        NSLog(@"----------waiting for devices");
    
    // find soundflower devices, store and remove them from our output list
    AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
    int index = 0;
    for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i, ++index) {
        if (0 == strcmp("Soundflower (2ch)", (*i).mName)) {
            inputDeviceID = (*i).mID;
            AudioDeviceList::DeviceList::iterator toerase = i;
            i--;
            thelist.erase(toerase);
            NSLog(@"Found Sound Flower! Need to add case when it wasn't found");
        }
    }
    
    UInt32 one = 1;
    
    // Set the current device to the default input unit.
    err = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &inputDeviceID, sizeof(AudioDeviceID) );
    //err = AudioHardwareGetProperty( kAudioHardwarePropertyDefaultInputDevice, &one, &inputDeviceID );
    if (err) {
        NSLog(@"Audio Error: CurrentDevice: %d", err);
    }
    /*  Back to normal  */
    
    //  Enable input and output on AURemoteIO
    //  Input is enabled on the input scope of the input element
    //  Output is enabled on the output scope of the output element
    
    
    err = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    if (err) {
        NSLog(@"Audio Error: 1: %d", err);
    }
    
    err = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
    if (err) {
        NSLog(@"Audio Error: 2: %d", err);
    }
    
    // Explicitly set the input and output client formats
    // sample rate = 44100, num channels = 1, format = 32 bit floating point
    
    AudioStreamBasicDescription audioFormat = [self getAudioDescription];
    /////
    AudioStreamBasicDescription	deviceFormat;
    UInt32 param = sizeof(AudioStreamBasicDescription);
    err = AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1, &deviceFormat, &param );
    if(err != noErr)
    {
        NSLog(@"Error getting stuff");
    }
    NSLog(@"%d", deviceFormat.mChannelsPerFrame);
    /////
    err = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &audioFormat, sizeof(audioFormat));
    if (err) {
        NSLog(@"Audio Error: 3: %d", err);
    }
    
    err = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(audioFormat));
    if (err) {
        NSLog(@"Audio Error: 4: %d", err);
    }
    
    // Set the MaximumFramesPerSlice property. This property is used to describe to an audio unit the maximum number
    // of samples it will be asked to produce on any single given call to AudioUnitRender
    UInt32 maxFramesPerSlice = 4096;
    err = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(UInt32));
    if (err) {
        NSLog(@"Audio Error: 5: %d", err);
    }
    
    // Get the property value back from AURemoteIO. We are going to use this value to allocate buffers accordingly
    UInt32 propSize = sizeof(UInt32);
    err = AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize);
    if (err) {
        NSLog(@"Audio Error: 6: %d", err);
    }
    
    AURenderCallbackStruct renderCallback;
    renderCallback.inputProc = recordingCallback;
    renderCallback.inputProcRefCon = (__bridge void *)(self);
    
    err = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 0, &renderCallback, sizeof(renderCallback));
    
    
    // Initialize the AURemoteIO instance
    AudioUnitInitialize(_audioUnit);
    
    AudioOutputUnitStart(_audioUnit);
    
    NSLog(@"Audio Started");
}

- (AudioStreamBasicDescription)getAudioDescription {
    AudioStreamBasicDescription audioDescription = {0};
    audioDescription.mFormatID          = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags       = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian;
    audioDescription.mChannelsPerFrame  = 1;
    audioDescription.mBytesPerPacket    = sizeof(SInt16)*audioDescription.mChannelsPerFrame;
    audioDescription.mFramesPerPacket   = 1;
    audioDescription.mBytesPerFrame     = sizeof(SInt16)*audioDescription.mChannelsPerFrame;
    audioDescription.mBitsPerChannel    = 8 * sizeof(SInt16);
    audioDescription.mSampleRate        = 44100.0;
    return audioDescription;
}

-(void) writeDataToClients:(NSData *)data
{
    [self.delegate sendEncodedData:data type:CCNetworkAudioData];
}

-(void) stop
{
    AudioOutputUnitStop(_audioUnit);
}

-(void) dealloc
{
    AudioOutputUnitStop(_audioUnit);
}

@end

