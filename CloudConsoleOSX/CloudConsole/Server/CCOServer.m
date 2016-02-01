//
//  CCOServer.m
//  CloudConsole
//
//  Created by Will Cobb on 1/5/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
// https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/rpcbind.8.html
#import "CCOServer.h"
#import "CCNetworkProtocol.h"
#import "CCOServerBroadcaster.h"

#import "PortMapper.h"
#import "CCGame.h"

#import "CCPlugin.h"


@interface CCOServer () {
    BOOL running;
    CCOServerBroadcaster *broadcaster;
    CCOVideoStream      *videoStream;
    PortMapper          *portMapper;
    CCUdpSocket         *serverSocket;
    
    NSArray             *currentGames;
    NSRunningApplication *currentApplication;
    
    CCPlugin            *currentPlugin;
}

@end

@implementation CCOServer

+ (id)sharedInstance {
    static CCOServer * s = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[self alloc] init];
    });
    return s;
}

- (id)init
{
    if (self = [super init]) {
        currentGames = [CCGame gamesAtPaths:[CCGame defaultPaths]];
        broadcaster = [[CCOServerBroadcaster alloc] init];
    }
    return self;
}

- (void)start
{
    if (running) return;
    running = YES;
    NSLog(@"Server Started");
    [self mapSocket];
    [broadcaster start];
}

- (void)mapSocket
{
    serverSocket = [[CCUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    serverSocket.applicationState = CCStateHome;
    NSError *error = nil;
    [serverSocket bindToPort:5467 error:&error];
    if (error) {
        NSLog(@"Error starting server (bind): %@", error);
        return;
    }
    [serverSocket beginReceiving:&error];
    if (error) {
        NSLog(@"Error starting server (receive): %@", error);
        return;
    }
    NSLog(@"Opened socket to: %d", serverSocket.localPort);
    
    // Not working
    
    portMapper = [[PortMapper alloc] initWithPort:serverSocket.localPort];
    /*portMapper.mapTCP=NO;
    portMapper.mapUDP=YES;
    portMapper.desiredPublicPort = 17483;
    [portMapper open];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(portMapChanged:)
                                                 name: PortMapperChangedNotification
                                               object: nil];
     */
    
}

#pragma mark - Network

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    uint32_t *message = (uint32_t *)data.bytes;
    switch (message[0]) {
        case CCNetworkOpenStream: {
            [broadcaster stop];
            uint32_t port = message[1];
            NSString *applicationPath = [NSString stringWithCString:(void *)message+12 encoding:NSUTF8StringEncoding];
            //NSString *applicationName = [[CCGame applicationNameForPath:applicationPath] stringByDeletingPathExtension];
            NSLog(@"Open Data: %@", data);
            NSLog(@"Launch: %@", applicationPath);
            
            
            currentApplication = [currentPlugin.plugin launchGameWithPath:applicationPath];
            if (!currentApplication) {
                NSLog(@"Plugin couldn't launch game");
                [serverSocket sendData:[NSData data] withTimeout:-1 CCtag:CCNetworkStreamOpenFailure];
                [broadcaster start];
                return;
            }
            serverSocket.applicationState = CCStateInStream;
            
            //Wait for app to start
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"Waiting for game to start");
                for (int i = 0; i < 10 && !currentApplication.finishedLaunching; i++) {
                    [NSThread sleepForTimeInterval:1];
                }
                
                [NSThread sleepForTimeInterval:3]; //Just some assurance that the game has launched
                
                NSLog(@"Open Stream to %@:%d", [GCDAsyncUdpSocket hostFromAddress:address], port);
                [self startCaptureFromProcess:currentApplication.processIdentifier
                                       ToHost:[GCDAsyncUdpSocket hostFromAddress:address]
                                         Port:port];
                [serverSocket sendData:[NSData data] withTimeout:-1 CCtag:CCNetworkStreamOpenSuccess];
            });
            break;
        }
        case CCNetworkGetAvaliableGames: {
            currentGames = [CCGame gamesAtPaths:[CCGame defaultPaths]];
            NSLog(@"Found Games: %@", currentGames);
            NSMutableArray *gameArray = [NSMutableArray array];
            for (int i = 0; i < currentGames.count; i++) {
                [gameArray addObject:[currentGames[i] dataRepresentation]];
            }
            
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:gameArray
                                                               options:0
                                                                 error:&error];
            if (!jsonData) {
                NSLog(@"Got an error creating json: %@", error);
                return;
            }
            [serverSocket sendData:jsonData withTimeout:-1 CCtag:CCNetworkGetAvaliableGames];
            break;
        }
        case CCNetworkGetSubGames: {
            NSString *applicationPath = [NSString stringWithCString:(void *)message+8 encoding:NSUTF8StringEncoding];
            NSString *applicationName = [[CCGame applicationNameForPath:applicationPath] stringByDeletingPathExtension];
            /*  Load Plugin  */
            currentPlugin = [[CCPlugin alloc] initWithName:applicationName];
            
            //Subgames aren't actual CCGames but what the data rep would be
            NSArray *subGames = [currentPlugin.plugin subGames];
            NSMutableArray *gameArray = [NSMutableArray array];
            for (int i = 0; i < subGames.count; i++) {
                [gameArray addObject:subGames[i]];
            }
            
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:gameArray
                                                               options:0
                                                                 error:&error];
            if (!jsonData) {
                NSLog(@"Got an error creating json: %@", error);
                return;
            }
            [serverSocket sendData:jsonData withTimeout:-1 CCtag:CCNetworkGetSubGames];
            break;
        }
        default:
            NSLog(@"CCOServer got unknown Tag: %u", message[0]);
            break;
    }
}

#pragma mark - Socket Delegate

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    NSLog(@"Socket closed");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    NSLog(@"Server connected to client");
}
- (void)portMapChanged: (NSNotification*)n
{
    NSLog(@"%@", n);
    NSLog(@"Port is open on ip:%@, port: %hu", portMapper.publicAddress, portMapper.publicPort);
}

- (void)wrongApplicationState
{
    
}

- (void)streamClosed
{
    serverSocket.delegate = self;
    videoStream = nil;
    serverSocket.applicationState = CCStateHome;
    NSLog(@"Closed stream");
}

- (NSString *)currentIP
{
    return [PortMapper localAddress];
}

- (uint16_t)currentPort
{
    return serverSocket.localPort;
}

#pragma mark - Capturing
//Eventually pass game pid or path
- (void)startCaptureFromProcess:(pid_t)pid ToHost:(NSString *)host Port:(uint16_t)port
{
    videoStream = [[CCOVideoStream alloc] initWithGamePid:pid delegate:self];
    serverSocket.delegate = videoStream;
    
    if (![videoStream beginStreamWithSocket:serverSocket]) {
        NSLog(@"Unable to start stream");
        return;
        //We should show an error here
    }
    
    NSLog(@"Stream Started!");
}

@end