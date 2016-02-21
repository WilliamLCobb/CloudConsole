//
//  CCOServer.m
//  CloudConsole
//
//  Created by Will Cobb on 1/5/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
// https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/rpcbind.8.html

#import "CCOServer.h"
#import "AppDelegate.h"
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
    
    NSMutableDictionary  *socketDelegates;
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
        self.deviceName = [NSString stringWithFormat:@"mac.%@", [[NSHost currentHost] localizedName]];
        socketDelegates = [NSMutableDictionary dictionary];
        currentGames = [CCGame gamesAtPaths:[CCGame defaultPaths]];
    }
    return self;
}

- (void)start
{
    NSLog(@"Starting");
    if (running) return;
    running = YES;
    NSLog(@"Server Started");
    [self mapSocket];
    broadcaster = [[CCOServerBroadcaster alloc] init];
    [broadcaster startBroadcastWithName:self.deviceName];
}

- (void)mapSocket
{
    serverSocket = [[CCUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    serverSocket.applicationState = CCStateHome;
    NSError *error = nil;
    [serverSocket bindToPort:CCNetworkServerPort error:&error];
    if (error) {
        NSLog(@"Error starting server (bind): %@", error);
        return;
    }
    [serverSocket beginReceiving:&error];
    if (error) {
        NSLog(@"Error starting server (receive): %@", error);
        return;
    }
    // Not working
    
    //portMapper = [[PortMapper alloc] initWithPort:serverSocket.localPort];
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
- (void) CCSocket:(CCUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withTag:(uint32_t)tag
{
    uint32_t *message = (uint32_t *)data.bytes;
    switch (tag) {
        case CCNetworkReopenStream: {
            [broadcaster stop];
            NSLog(@"Reopening not supported");
        }
        case CCNetworkOpenStream: {
            [broadcaster stop];
            NSLog(@"Launching Game");
            //Switch to JSON later
            
            uint32_t port = message[0];
            NSString *applicationPath = [NSString stringWithCString:(void *)message+8 encoding:NSUTF8StringEncoding];
            
            NSString *applicationName = [[CCGame applicationNameForPath:applicationPath] stringByDeletingPathExtension];
            /*  Load Plugin  */
            currentPlugin = [[CCPlugin alloc] initWithName:applicationName];
            
            // Reopen running game
            if ([applicationPath isEqualToString:self.currentGame.path]) {
                [self startCaptureFromProcess:currentApplication.processIdentifier
                                       ToHost:[GCDAsyncUdpSocket hostFromAddress:address]
                                         Port:port];
                return;
            } else {
                NSLog(@"New Game");
                NSLog(@"Current %@", self.currentGame.path);
                NSLog(@"New: %@", applicationPath);
            }
            
            // Launch new game
            if (currentApplication) {
                if (![currentApplication terminate]) {
                    NSLog(@"Force Quitting");
                    [currentApplication forceTerminate];
                }
            }
            
            currentApplication = nil;
            self.currentGame = nil;
            
            NSLog(@"Launch: %@", applicationPath);
            
            
            currentApplication = [currentPlugin launchGameWithPath:applicationPath];
            if (!currentApplication) {
                NSLog(@"Plugin couldn't launch game");
                [serverSocket sendData:[NSData data] usingMethod:CCUdpSendMethodGuarentee CCtag:CCNetworkStreamOpenFailure];
                [broadcaster startBroadcastWithName:self.deviceName];
                return;
            } else {
                for (CCGame *game in currentGames) {
                    if ([game.path isEqualToString:[CCGame processPathFromPid:currentApplication.processIdentifier]]) {
                        self.currentGame = game;
                        break;
                    }
                }
            }
            serverSocket.applicationState = CCStateInStream;
            
            // Wait for app to start
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
                [serverSocket sendData:[NSData data] usingMethod:CCUdpSendMethodGuarentee CCtag:CCNetworkStreamOpenSuccess];
                [AppDelegate.sharedInstance preventSleep];
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
            //NSLog(@"Sending: %@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
            [serverSocket sendData:jsonData usingMethod:CCUdpSendMethodGuarentee CCtag:CCNetworkGetAvaliableGames];
            
            break;
        }
        case CCNetworkGetSubGames: {
            //Switch to JSON
            NSString *applicationPath = [NSString stringWithCString:(void *)message+4 encoding:NSUTF8StringEncoding];
            NSString *applicationName = [[CCGame applicationNameForPath:applicationPath] stringByDeletingPathExtension];
            /*  Load Plugin  */
            currentPlugin = [[CCPlugin alloc] initWithName:applicationName];
            
            //Subgames aren't actual CCGames but what the data rep would be
            NSArray *subGames = [currentPlugin subGames];
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
            [serverSocket sendData:jsonData usingMethod:CCUdpSendMethodGuarentee CCtag:CCNetworkGetSubGames];
            break;
        }
        default:
        {
            NSString *bufferTag = [NSString stringWithFormat:@"%u", tag];
            id <CCUdpSocketDelegate> delegate = [socketDelegates objectForKey:bufferTag];
            if (delegate) {
                [delegate CCSocket:sock didReceiveData:data fromAddress:address withTag:tag];
                return;
            }
            WARNING_LOG(@"CCOServer got unknown tag: %@", bufferTag);
            break;
        }
    }
}

- (void)registerDelegate:(id<CCUdpSocketDelegate>)delegate forBuffer:(uint32_t)abuffer
{
    NSString *bufferTag = [NSString stringWithFormat:@"%u", abuffer];
    __weak id weakDel = delegate;
    socketDelegates[bufferTag] = weakDel;
}

- (NSDictionary *)currentGameInfo
{
    if (!self.currentGame)
        return nil;
    return [self.currentGame dataRepresentation];
}

#pragma mark - Socket Delegate

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    INFO_LOG(@"Socket closed");
}

- (void)udpSocket:(CCUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    INFO_LOG(@"Server connected to client");
    [sock sendData:[NSData new] usingMethod:CCUdpSendMethodGuarentee CCtag:CCNetworkConnect];
    [[AppDelegate sharedInstance] shake];
}
- (void)portMapChanged: (NSNotification*)n
{
    INFO_LOG(@"Port is open on ip:%@, port: %hu", portMapper.publicAddress, portMapper.publicPort);
}

- (void)wrongApplicationState
{
    
}

- (void)CCSocketTimedOut
{
    [self streamClosed];
}

- (void)streamClosed
{
    serverSocket.delegate = self;
    videoStream = nil;
    serverSocket.applicationState = CCStateHome;
    INFO_LOG(@"Back in CCOServer");
    [broadcaster startBroadcastWithName:self.deviceName];
    
    INFO_LOG(@"CLosing App");
    if (currentApplication) {
        if (![currentApplication terminate]) {
            INFO_LOG(@"Force Quitting");
            [currentApplication forceTerminate];
        }
    }
    self.currentGame = nil;
    
    [AppDelegate.sharedInstance allowSleep];
}

- (NSString *)currentIP
{
    return [PortMapper localAddress];
}

- (uint16_t)currentPort
{
    return serverSocket.localPort;
}

- (BOOL)connected
{
    return serverSocket.connected;
}

#pragma mark - Capturing
//Eventually pass game pid or path
- (void)startCaptureFromProcess:(pid_t)pid ToHost:(NSString *)host Port:(uint16_t)port
{
    videoStream = [[CCOVideoStream alloc] initWithGamePid:pid delegate:self];
    serverSocket.delegate = videoStream;
    
    if (![videoStream beginStreamWithSocket:serverSocket]) {
        ERROR_LOG(@"Unable to start stream");
        [self streamClosed];
        return;
        //We should show an error here
    }
    
    INFO_LOG(@"Stream Started!");
}

@end
