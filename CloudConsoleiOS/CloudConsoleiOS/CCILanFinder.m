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
#import "GCDAsyncUdpSocket.h"

#import <UIKit/UIKit.h>

@interface CCILanFinder ()  {
    BonjourHandler  *bonjourSocket;
    NSString        *connectingName;
    ScanLAN         *lanScanner;
    GCDAsyncUdpSocket *pingSocket;
}

@end

@implementation CCILanFinder

- (id)init
{
    if (self = [super init]) {
        pingSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        if (![pingSocket beginReceiving:nil]) {
            NSLog(@"Error creating ping socket");
        }
        lanScanner = [[ScanLAN alloc] initWithDelegate:self];
    }
    return self;
}

- (void)start
{
    self.services = [NSMutableArray new];
    self.devices = [NSMutableArray new];
    
    //Load Saved devices
    NSMutableDictionary *deviceDictionairy = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Devices"] mutableCopy];
    if (deviceDictionairy) {
        for (NSString *key in deviceDictionairy.allKeys) {
            NSData *deviceData = deviceDictionairy[key];
            [self.devices addObject:[NSKeyedUnarchiver unarchiveObjectWithData:deviceData]];
        }
        [self.delegate devicesFound];
    }
    
    if (![lanScanner startScan] && kUseBonjour) {
        NSLog(@"Lan Scanner not working, trying bonjour");
        NSString *name = [NSString stringWithFormat:@"iphone.%@", [[UIDevice currentDevice] name]];
        bonjourSocket = [[BonjourHandler alloc] initWithName:name];
        bonjourSocket.delegate = self;
        [bonjourSocket start];
    }
}

- (void)stop
{
    if (kUseBonjour) {
        [bonjourSocket stop];
        bonjourSocket = nil;
    }
    [lanScanner stopScan];
}

- (void)addDevice:(CCIDevice *)device
{
    if (![self.devices containsObject:device]) {
        [self.devices removeObject:device];
        [self.devices addObject:device]; // This updates the port and host
    } else {
        NSLog(@"%@ already in device list", device);
    }
    //Remove Dupe services
    for (NSNetService *s in self.services) {
        if ([self.devices containsObject:s]) {
            [self.services removeObject:s];
            NSLog(@"Removing %@ from services", s.name);
        } else {
            NSLog(@"Devices %@ does not contain service: %@", self.devices, s.name);
        }
    }
    [self.delegate devicesFound];
}

- (void)addBonjourServices:(NSArray <NSNetService *> *)services
{
    [self.services removeAllObjects];
    for (NSNetService *s in services) {
        if (![self.devices containsObject:s]) {
            [self.services addObject:s];
        }
    }
    [self.delegate devicesFound];
}

- (void)saveDevice:(CCIDevice *)device
{
    NSMutableDictionary *deviceDictionairy = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Devices"] mutableCopy];
    if (!deviceDictionairy) {
        deviceDictionairy = [NSMutableDictionary new];
    }
    deviceDictionairy[device.name] = [NSKeyedArchiver archivedDataWithRootObject:device];
    [[NSUserDefaults standardUserDefaults] setObject:deviceDictionairy forKey:@"Devices"];
}

#pragma mark - Lan Scan Delegate

- (void)scanLANDidFindNewAdrress:(NSString *)address havingHostName:(NSString *)hostName
{
    NSLog(@"Ping %@", address);
    uint32_t pingTag = CCNetworkPing;
    [pingSocket sendData:[NSData dataWithBytes:&pingTag length:4] toHost:address port:CCNetworkServerPort withTimeout:-1 tag:0];
}

- (void)scanLANDidFinishScanning
{
    
}

- (void)CCSocket:(CCUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withTag:(uint32_t)tag
{
    NSString *host = [CCUdpSocket hostFromAddress:address];
    uint16_t port  = [CCUdpSocket portFromAddress:address];
    CCIDevice *newDevice = [[CCIDevice alloc] initWithName:@"Pinged device" host:host port:port];
    [self.devices addObject:newDevice];
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
    NSLog(@"New Services: %@", services);
    [self addBonjourServices:services];
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
                [self addDevice:newDevice];
            }
            break;
        }
        default:
            NSLog(@"Bonjour unknown tag");
            break;
    }
}

@end






