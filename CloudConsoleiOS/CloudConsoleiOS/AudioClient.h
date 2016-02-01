//
//  AudioClient.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/21/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "GCDAsyncSocket.h"

#import "TPCircularBuffer.h"

@protocol AudioClientDelegate

-(void) connected;
-(void) animateSoundIndicator:(float) rms;

@end

@interface AudioClient : NSObject
{
    NSString *ipAddress;
    BOOL stopped;
}

@property (nonatomic) TPCircularBuffer circularBuffer;
@property (nonatomic) AudioComponentInstance audioUnit;
@property (nonatomic, strong) id delegate;

-(id)initWithDelegate:(id)delegate;
-(void) start;
-(void) stop;
-(TPCircularBuffer *) buffer;
-(void)parseData:(NSData *)data;

@end
