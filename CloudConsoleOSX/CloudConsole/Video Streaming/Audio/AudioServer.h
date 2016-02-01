//
//  AudioServer.h
//  CloudConsole
//
//  Created by Will Cobb on 1/21/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "GCDAsyncUdpSocket.h"
#import "CCOVideoStream.h"
@interface AudioServer : NSObject

@property (nonatomic, weak) CCOVideoStream *delegate; //Change this to a protocol later

@property (nonatomic, strong)NSMutableArray *connectedClients;

@property (nonatomic) AudioComponentInstance audioUnit;

-(void) start;
-(void) stop;
-(void) writeDataToClients:(NSData*)data;

@end
