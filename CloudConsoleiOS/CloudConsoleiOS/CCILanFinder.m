//
//  CCILANFinder.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/26/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCILanFinder.h"
#import "CCNetworkProtocol.h"
#import "CCIDevice.h"


@interface CCILanFinder ()  {
    BonjourHandler  *bonjourSocket;
    NSString        *connectingName;
}

@end

@implementation CCILanFinder

- (id)init
{
    if (self = [super init]) {
        self.services = [NSMutableArray new];
        self.devices = [NSMutableArray new];
        
        //When Bonjour doesn't work
        CCIDevice *testDevice = [[CCIDevice alloc] initWithName:@"mac.Mac:10 0 1 20" host:@"10.0.1.20" port:5467];
        CCIDevice *testDevice2 = [[CCIDevice alloc] initWithName:@"mac.Mac:192 168 1 132" host:@"192.168.1.132" port:5467];
        [self.devices addObject:testDevice];
        [self.devices addObject:testDevice2];
        
    }
    return self;
}

- (void)start
{
    if (kUseBonjour) {
        bonjourSocket = [[BonjourHandler alloc] init];
        bonjourSocket.delegate = self;
        [bonjourSocket start];
    }
}

- (void)stop
{
    [bonjourSocket stop];
    bonjourSocket = nil;
}

#pragma mark - Bonjour Delegate

- (void)getServiceDestination:(NSNetService *)service
{
    connectingName = service.name;
    [bonjourSocket connectToService:service];
}

- (void)bonjourHandlerConnected:(BonjourHandler *)handler
{
    NSLog(@"Connection Established");
}

- (void)bonjourHandlerDisconnected:(BonjourHandler *)handler
{
    NSLog(@"Bonjour Connection Lost");
}

- (void)bonjourHandler:(BonjourHandler *)handler updatedServices:(NSMutableArray *)services
{
    NSLog(@"New Services: %ld", services.count);
    [self.services removeAllObjects];
    //Should lock here
    for (NSNetService *s in services) {
        if (![self.devices containsObject:s]) {
            NSLog(@"Devices %@ does not contain: %@", self.devices, s.name);
            [self.services addObject:s];
        }
    }
    [self.delegate devicesFound];
}

- (void)bonjourHandler:(BonjourHandler *)handler recievedData:(NSData *)data
{
    NSLog(@"Got data");
    uint32_t *message = (uint32_t*)data.bytes;
    switch (message[0]) {
        case CCBonjourServerAddress:
        {
            uint16_t  port = message[1];
            NSString *host = [NSString stringWithCString:(char *)&message[2] encoding:NSUTF8StringEncoding];
            NSString *name = [NSString stringWithCString:(char *)&message[2] + host.length + 1 encoding:NSUTF8StringEncoding];
            if (name == connectingName) {
                NSLog(@"Got info for selected device");
                [self.delegate gotServiceDestination:host port:port];
            } else {
                NSLog(@"Adding device");
                CCIDevice *newDevice = [[CCIDevice alloc] initWithName:name host:host port:port];
                if (![self.devices containsObject:newDevice]) {
                    [self.devices removeObject:newDevice];
                    [self.devices addObject:newDevice];
                    NSLog(@"%@", self.devices);
                } else {
                    NSLog(@"%@ already in device list", newDevice);
                }
                //Should lock here
                //Remove Dupe services
                for (NSNetService *s in self.services) {
                    if ([self.devices containsObject:s]) {
                        [self.services removeObject:s];
                        NSLog(@"Removing %@ from services", s.name);
                    } else {
                        NSLog(@"Devices %@ does not contain: %@", self.devices, s.name);
                    }
                }
                [self.delegate devicesFound];
            }
            break;
        }
        default:
            NSLog(@"Bonjour unknown tag");
            break;
    }
}

@end






