//
//  CCIDevice.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/26/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BonjourHandler.h"

typedef NS_ENUM(NSInteger, CCIDeviceDiscoverType) {
    CCIDeviceDiscoverTypeFavorite,
    CCIDeviceDiscoverTypeGoogle,
    CCIDeviceDiscoverTypeLAN,
};

typedef NS_ENUM(NSInteger, CCIDeviceavailability) {
    CCIDeviceavailabilityUnknown,
    CCIDeviceavailabilityAvaliable,
    CCIDeviceavailabilityNotAvaliable,
    CCIDeviceavailabilityInStream
};

@class CCIGame;
@interface CCIDevice : NSObject

@property NSString *name;
@property NSString *deviceName;
@property NSString *host;
@property uint16_t  port;
@property CCIDeviceDiscoverType discoverType;
@property CCIGame  *currentGame;
@property CFTimeInterval validTime;

@property CCIDeviceavailability availability;

- (id)initWithName:(NSString *)name deviceName:(NSString *)deviceName host:(NSString *)host port:(uint16_t)port discoverType:(CCIDeviceDiscoverType)discoverType;
- (void)pingDevice;
- (BOOL)valid;
@end
