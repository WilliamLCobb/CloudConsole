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
#import "CCIGame.h"

#import <UIKit/UIKit.h>

@interface CCILanFinder ()  {
    BonjourHandler  *bonjourSocket;
    NSString        *connectingName;
    ScanLAN         *lanScanner;
    CCUdpSocket     *pingSocket;
    
    BOOL            scanning;
}

@end

@implementation CCILanFinder

- (id)init
{
    if (self = [super init]) {
        self.devices = [NSMutableArray new];
        pingSocket = [[CCUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        lanScanner = [[ScanLAN alloc] initWithDelegate:self];
    }
    return self;
}

- (void)start
{
    [self.devices removeAllObjects];
    
    // Reset saved
    //[[NSUserDefaults standardUserDefaults] setObject:[NSMutableDictionary new] forKey:@"Devices"];
    
    //Load Saved devices
    NSMutableDictionary *deviceDictionairy = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Devices"] mutableCopy];
    NSMutableArray *keysToRemove = [NSMutableArray new];
    if (deviceDictionairy) {
        for (NSString *key in deviceDictionairy.allKeys) {
            NSData *deviceData = deviceDictionairy[key];
            CCIDevice *savedDevice =[NSKeyedUnarchiver unarchiveObjectWithData:deviceData];
            if (savedDevice.valid) {
                [self addDevice:savedDevice];
            } else {
                [keysToRemove addObject:key];
            }
        }
        [self.delegate devicesFound];
    }
    [deviceDictionairy removeObjectsForKeys:keysToRemove];
    [[NSUserDefaults standardUserDefaults] setObject:deviceDictionairy forKey:@"Devices"];
    
    if (![lanScanner startScan] && kUseBonjour) {
        NSLog(@"Lan Scanner not working, trying bonjour");
        NSString *name = [NSString stringWithFormat:@"iphone.%@", [[UIDevice currentDevice] name]];
        bonjourSocket = [[BonjourHandler alloc] initWithName:name];
        bonjourSocket.delegate = self;
        [bonjourSocket start];
    }
    scanning = YES;
}

- (void)stop
{
    if (kUseBonjour) {
        [bonjourSocket stop];
        bonjourSocket = nil;
    }
    [lanScanner stopScan];
    scanning = NO;
}

- (void)addDevice:(CCIDevice *)device
{
    if ([self.devices containsObject:device]) {
        //[self.devices removeObject:device];
        //[self.devices addObject:device]; // This updates the port and host
    } else {
        [self.devices addObject:device];
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
    [pingSocket pingHost:address port:CCNetworkServerPort];
}

- (void)scanLANDidFinishScanning
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (scanning) {
            [lanScanner startScan];
        }
    });
}

#pragma mark - Socket Delegate

- (void)CCSocket:(CCUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withTag:(uint32_t)tag
{
    if (tag != CCNetworkPingResponse) {
        ERROR_LOG(@"Host sending wrong data");
        //Send disconnect packet here
        return;
    }
    NSString *host = [CCUdpSocket hostFromAddress:address];
    uint16_t port  = [CCUdpSocket portFromAddress:address];
    //CCIDevice *newDevice = [[CCIDevice alloc] initWithName:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] host:host port:port];
    NSString *deviceInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray  *deviceInfoComponents = [deviceInfo componentsSeparatedByString:@"."];
    INFO_LOG(@"Ping Response from: %@", deviceInfo);
    if (deviceInfoComponents.count != 2) {
        ERROR_LOG(@"Invalid Ping response");
        return;
    }
    CCIDevice *newDevice = [[CCIDevice alloc] initWithName:deviceInfoComponents[1]
                                                deviceName:deviceInfoComponents[0]
                                                      host:host
                                                      port:port
                                              discoverType:CCIDeviceDiscoverTypeLAN];
    [self addDevice:newDevice];
}

- (void)wrongApplicationState
{
    
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
    /* Does Not Work! */
    NSLog(@"Got data");
    uint32_t *message = (uint32_t*)data.bytes;
    switch (message[0]) {
        case CCBonjourServerAddress:
        {
            NSError *error;
            NSDictionary *deviceDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                NSLog(@"CCBonjourServerAddress json error");
            }
            
            NSString    *name = deviceDict[@"name"];
            NSString    *host = deviceDict[@"host"];
            uint16_t     port = [deviceDict[@"port"] integerValue];
            
            if (name == connectingName) {
                NSLog(@"Got info for selected device");
                [self.delegate gotServiceDestination:host port:port];
            } else {
                NSLog(@"Adding device");
                //Fix this part
//                CCIDevice *newDevice = [[CCIDevice alloc] initWithName:name host:host port:port];
//                if (deviceDict[@"currentGame"]) {
//                    CCIGame *currentGame = [[CCIGame alloc] initWithDictionairy:deviceDict[@"currentGame"]];
//                    newDevice.currentGame = currentGame;
//                }
//                [self addDevice:newDevice];
            }
            break;
        }
        default:
            NSLog(@"Bonjour unknown tag");
            break;
    }
}

@end






