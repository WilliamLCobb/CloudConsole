//
//  CCINetworkController.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/11/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
//  https://github.com/stig/json-framework

#import "CCNetworkProtocol.h"
#import "CCINetworkController.h"
#import "CCIStreamDecoder.h"
#import "CCIStreamManager.h"
#import "PortMapper.h"
#import "CCIGame.h"
#import "AppDelegate.h"

@interface CCINetworkController () {
    CCUdpSocket         *clientSocket;
    PortMapper          *portMapper;
    NSMutableData       *buffer;
    dispatch_queue_t    socketQueue;
    
    NSMutableDictionary *socketDelegates;
    NSMutableDictionary *progressDelegates;
    
    BOOL                connected;
    BOOL                notifiedUpdate;
}

@end

@implementation CCINetworkController

- (id)initWithHost:(NSString *)host port:(uint16_t)port
{
    if (self = [super init]) {
        socketDelegates = [NSMutableDictionary dictionary];
        progressDelegates = [NSMutableDictionary dictionary];
        socketQueue = dispatch_queue_create("Socket Delegate Queue", NULL);
        clientSocket = [[CCUdpSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
        
        [clientSocket setDestinationHost:host port:port]; //
        [clientSocket sendData:[NSData new] usingMethod:CCUdpSendMethodStream CCtag:CCNetworkConnect];
        /*portMapper = [[PortMapper alloc] initWithPort:CCNetworkInternalStreamPort];
        portMapper.mapUDP = YES;
        portMapper.mapTCP = NO;
        [portMapper open];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(portMapChanged:)
                                                     name: PortMapperChangedNotification
                                                   object: nil];
        */
        self.applications = [NSMutableArray new];
        self.addableApplications = [NSMutableArray new];
    }
    
    return self;
}

- (CCIStreamManager *)startStreamWithGame:(CCIGame *)game {
    NSLog(@"Starting Stream");
    CCIStreamManager *streamManager = [[CCIStreamManager alloc] init];
    
    [clientSocket reset];
    streamManager.streamSocket = clientSocket;
    clientSocket.applicationState = CCStateInStream;
    clientSocket.delegate = streamManager;
    
    uint32_t streamOptions = 0;
    uint32_t streamPort;
    //Need to check if we're on the same network as the client
    streamPort = clientSocket.localPort;
    
    uint32_t headerData[2] = {clientSocket.localPort, streamOptions};
    NSMutableData *sendData = [NSMutableData dataWithBytes:headerData length:2 * 4];
    [sendData appendBytes:[game.path UTF8String] length:game.path.length + 1];
    [clientSocket sendData:sendData usingMethod:CCUdpSendMethodGuarentee CCtag:CCNetworkOpenStream];
    return streamManager;
}

- (void)portMapChanged: (NSNotification*)n
{
    NSLog(@"Port is open on ip:%@, port: %hu", portMapper.publicAddress, portMapper.publicPort);
}

- (void)CCSocket:(CCUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withTag:(uint32_t)tag
{
    switch (tag) {
        case CCNetworkGetApplications:
        {
            NSError *error;
            NSArray *gamesArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                NSLog(@"Avaliable games json error: %@", [error description]);
                return;
            }
            [self willChangeValueForKey:@"applications"];
            [self.applications removeAllObjects];
            
            for (NSDictionary *gameDict in gamesArray) {
                [self.applications addObject:[[CCIGame alloc] initWithDictionairy:gameDict]];
            }
            
            if (error) {
                NSLog(@"Error loading games: %@", [error description]);
            }
            [self didChangeValueForKey:@"applications"];
            break;
        }
        case CCNetworkGetNewApplications:
        {
            NSError *error;
            NSArray *gamesArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                NSLog(@"Avaliable games json error: %@", [error description]);
                return;
            }
            [self willChangeValueForKey:@"addableApplications"];
            [self.addableApplications removeAllObjects];
            
            for (NSDictionary *gameDict in gamesArray) {
                [self.addableApplications addObject:[[CCIGame alloc] initWithDictionairy:gameDict]];
            }
            
            if (error) {
                NSLog(@"Error loading games: %@", [error description]);
            }
            [self didChangeValueForKey:@"addableApplications"];
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
            NSLog(@"CCINetworkController got unknown tag: %d", tag);
            break;
        }
    }
}

- (void)wrongApplicationState
{
    if (!notifiedUpdate) {
        [AppDelegate.sharedInstance showInfo:@"Download the newest version of Cloud Console for your Desktop at\ngoo.gl/U98vzy"
                                   withTitle:@"Out Of Data"];
        notifiedUpdate = YES;
    }
}

- (void)CCSocketTimedOut
{
    if ([self.delegate respondsToSelector:@selector(disconnectedFromServer)]) {
        [self.delegate disconnectedFromServer];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    connected = YES;
    if ([self.delegate respondsToSelector:@selector(connectedToServer)]) {
        [self.delegate connectedToServer];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    ERROR_LOG(@"Not Sending data");
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    WARNING_LOG(@"Closed socket: %@", error);
}

- (void)CCSocket:(CCUdpSocket *)sock downloadProgress:(float)progress forTag:(uint32_t)tag
{
    NSString *bufferTag = [NSString stringWithFormat:@"%u", tag];
    id <CCINetworkControllerDelegate> delegate = [progressDelegates objectForKey:bufferTag];
    if (delegate) {
        [delegate downloadProgress:progress forTag:tag];
        return;
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stream Manager Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)streamClosed
{
    clientSocket.applicationState = CCStateHome;
    clientSocket.delegate = self;
}

- (void)streamEnded
{
    //Ended stream to choose another game
    connected = NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Calls To Server
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)registerDelegate:(id<CCUdpSocketDelegate>)delegate forBuffer:(uint32_t)abuffer
{
    if (!clientSocket.connected)
        return NO;
    NSString *bufferTag = [NSString stringWithFormat:@"%u", abuffer];
    __weak id weakDel = delegate;
    socketDelegates[bufferTag] = weakDel;
    return YES;
}

- (BOOL)registerProgressDelegate:(id<CCINetworkControllerDelegate>)delegate forBuffer:(uint32_t)abuffer
{
    if (!clientSocket.connected)
        return NO;
    NSString *bufferTag = [NSString stringWithFormat:@"%u", abuffer];
    __weak id weakDel = delegate;
    progressDelegates[bufferTag] = weakDel;
    return YES;
}

- (BOOL)updateAvaliableApplications
{
    if (!clientSocket.connected) {
        NSLog(@"Warning: updateAvaliableGames socket not connected");
        return NO;
    }
    [clientSocket sendData:[NSData data] usingMethod:CCUdpSendMethodGuarentee CCtag:CCNetworkGetApplications];
    return YES;
}

- (BOOL)updateAddableApplications
{
    if (!clientSocket.connected) {
        NSLog(@"Warning: updateAddableGames socket not connected");
        return NO;
    }
    
    [clientSocket sendData:[NSData data] usingMethod:CCUdpSendMethodGuarentee CCtag:CCNetworkGetNewApplications];
    return YES;
}

- (void)addGame:(CCIGame *)game
{
    
}

- (BOOL)getSubGamesForDelegate:(id<CCUdpSocketDelegate>)delegate
{
    if (!clientSocket.connected)
        return NO;
    [self registerDelegate:delegate forBuffer:CCNetworkGetGames];
    [clientSocket sendData:[NSData data] usingMethod:CCUdpSendMethodGuarentee CCtag:CCNetworkGetGames];
    return YES;
}

- (BOOL)isConnected
{
    return connected;
}

- (void)dealloc
{
    [clientSocket close];
    clientSocket = nil;
    NSLog(@"Deallocating ccnc");
}

@end
