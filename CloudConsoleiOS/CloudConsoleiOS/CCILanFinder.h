//
//  CCILANFinder.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/26/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BonjourHandler.h"
#import "CCUdpSocket.h"
#import "ScanLAN.h"

@protocol CCILanDelegate <NSObject>

- (void)devicesFound;
- (void)gotServiceDestination:(NSString *)host port:(uint16_t)port;
- (void)scanFinished;
- (void)scanStarted;
@end

@class CCIDevice;

@interface CCILanFinder : NSObject <BonjourDelegate, CCUdpSocketDelegate, ScanLANDelegate>

@property (weak) id <CCILanDelegate>           delegate;
@property (nonatomic) NSMutableArray    *devices;
@property (nonatomic) NSMutableArray    *services;

- (void)getServiceDestination:(NSNetService *)service;
- (void)start;
- (void)stop;
- (void)saveDevice:(CCIDevice *)device;

@end
