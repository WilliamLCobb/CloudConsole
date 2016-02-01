//
//  ServerBroadcaster.m
//  CloudConsole
//
//  Created by Will Cobb on 1/30/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCOServerBroadcaster.h"
#import "AppDelegate.h"
#import "CCOServer.h"
#import "CCNetworkProtocol.h"

@interface CCOServerBroadcaster () {
    BonjourHandler  *bonjourSocket;
    NSMutableDictionary *seenServices;
}

@end

@implementation CCOServerBroadcaster

- (id)init
{
    if (self = [super init]) {
        seenServices = [NSMutableDictionary new];
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

- (void)bonjourHandlerConnected:(BonjourHandler *)handler
{
    NSLog(@"Bonjour Connection Established");
    
    uint32_t udpInfo = CCBonjourServerAddress;
    NSMutableData *sendData = [NSMutableData dataWithBytes:&udpInfo length:4];
    uint32_t port = [[CCOServer sharedInstance] currentPort];
    [sendData appendBytes:&port length:4];
    
    const char *IPString = [[[CCOServer sharedInstance] currentIP] UTF8String];
    [sendData appendBytes:IPString length:strlen(IPString) + 1];
    const char *nameString = [bonjourSocket.server.name UTF8String];
    [sendData appendBytes:nameString length:strlen(nameString) + 1];
    
    //Give time for our streams to set up
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [bonjourSocket send:sendData];
        [bonjourSocket closeStreams];
    });
}

- (void)bonjourHandlerDisconnected:(BonjourHandler *)handler
{
    NSLog(@"Bonjour Connection Lost");
}

- (void)bonjourHandler:(BonjourHandler *)handler updatedServices:(NSMutableArray *)services
{
    //NSLog(@"Devices avaliable: %@", services);
    for (NSNetService *s in services) {
        NSString *serviceHash = s.name;//[self serviceHash:s];
        if ((!seenServices[serviceHash] || CACurrentMediaTime() - [seenServices[serviceHash] floatValue] > 1.5) && bonjourSocket.streamOpenCount == 0) {
            NSLog(@"Connecting");
            [bonjourSocket connectToService:s];
            seenServices[serviceHash] = [NSNumber numberWithFloat:CACurrentMediaTime()];
            return;
        }
    }
}

- (NSString *)serviceHash:(NSNetService *)service
{
    return [NSString stringWithFormat:@"%ld", [service hash]];
}

- (void)bonjourHandler:(BonjourHandler *)handler recievedData:(NSData *)data
{
    NSLog(@"Recevied data?");
}

@end
