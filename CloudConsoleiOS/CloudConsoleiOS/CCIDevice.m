//
//  CCIDevice.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/26/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIDevice.h"
#import <UIKit/UIKit.h>
#import "CCUdpSocket.h"

@interface CCIDevice () {
    CCUdpSocket     *pingSocket;
    NSTimer         *pingTimer;
    BOOL            gotPingResponse;
}

@end

@implementation CCIDevice

- (void)commonInit
{
    self.availability = CCIDeviceavailabilityUnknown;
    gotPingResponse = YES;
    pingSocket = [[CCUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (id)initWithName:(NSString *)name deviceName:(NSString *)deviceName host:(NSString *)host port:(uint16_t)port discoverType:(CCIDeviceDiscoverType)discoverType
{
    if (self = [super init]) {
        self.name = name;
        self.deviceName = deviceName;
        self.host = host;
        self.port = port;
        self.discoverType = discoverType;
        if (discoverType == CCIDeviceDiscoverTypeLAN) {
            self.validTime = CACurrentMediaTime() + 3600 * 24; //Save recent for a day
        } else if (discoverType == CCIDeviceDiscoverTypeFavorite) {
            self.validTime = DBL_MAX;
        } else {
            self.validTime = CACurrentMediaTime() + 300; // 5 minutes
        }
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        self.name = [coder decodeObjectForKey:@"name"];
        self.deviceName = [coder decodeObjectForKey:@"deviceName"];
        self.host = [coder decodeObjectForKey:@"host"];
        self.port = (uint16_t)[coder decodeIntForKey:@"port"];
        self.validTime = [coder decodeDoubleForKey:@"time"];
        self.discoverType = [coder decodeIntegerForKey:@"type"];
        [self commonInit];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.deviceName forKey:@"deviceName"];
    [coder encodeObject:self.host forKey:@"host"];
    [coder encodeInteger:self.port forKey:@"port"];
    [coder encodeDouble:self.validTime forKey:@"time"];
    [coder encodeInteger:self.discoverType forKey:@"type"];
}

- (BOOL) isEqual:(id)object
{
    NSString *objectClass = NSStringFromClass([object class]);
    if ([objectClass isEqualToString:@"CCIDevice"]) {
        CCIDevice *other = object;
        return [other.name isEqualToString:self.name];
    } else if ([objectClass isEqualToString:@"NSNetService"]) {
        NSNetService *other = object;
        return [other.name isEqualToString:self.name];
    }
    NSLog(@"Error, unknown device compare");
    return NO;
}

#pragma - Calls

- (BOOL)valid
{
    return CACurrentMediaTime() < self.validTime;
}

- (void)pingDevice
{
    //Ping ran again without a response
    if (!gotPingResponse) {
        self.availability = CCIDeviceavailabilityNotAvaliable;
    }
    gotPingResponse = NO;
    [pingSocket pingHost:self.host port:self.port];
}

- (void)CCSocket:(CCUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withTag:(uint32_t)tag
{
    gotPingResponse = YES;
    self.availability = CCIDeviceavailabilityAvaliable;
}

-(void)dealloc
{
    [pingTimer invalidate];
    [pingSocket close];
    pingSocket = nil;
}

@end
