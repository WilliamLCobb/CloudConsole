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

@interface CCINetworkController () {
    CCUdpSocket         *clientSocket;
    PortMapper          *portMapper;
    NSMutableData       *buffer;
    dispatch_queue_t    socketQueue;
    
    NSMutableDictionary *socketDelegates;
    NSMutableDictionary *progressDelegates;
    
    BOOL                connected;
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
        //clientSocket = [[CCUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
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
        self.games = [NSMutableArray new];
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
        case CCNetworkGetAvaliableGames:
        {
            NSError *error;
            NSArray *gamesArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                NSLog(@"Avaliable games json error: %@", [error description]);
                //NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                return;
            }
            [self willChangeValueForKey:@"games"];
            [self.games removeAllObjects];
            
            for (NSDictionary *gameDict in gamesArray) {
                [self.games addObject:[[CCIGame alloc] initWithDictionairy:gameDict]];
            }
            
            if (error) {
                NSLog(@"Error loading games: %@", [error description]);
            }
            
            NSLog(@"Got %lu games (%ld)", (unsigned long)gamesArray.count, self.games.count);
            [self didChangeValueForKey:@"games"];
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
    NSLog(@"Socket client not in home state");
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

- (BOOL)updateAvaliableGames
{
    if (!clientSocket.connected) {
        NSLog(@"Warning: updateAvaliableGames socket not connected");
        return NO;
    }
    
    [clientSocket sendData:[NSData data] usingMethod:CCUdpSendMethodGuarentee CCtag:CCNetworkGetAvaliableGames];
    NSLog(@"%@ Asked for apps", self);
    return YES;
}

- (BOOL)getSubGamesForDelegate:(id<CCUdpSocketDelegate>)delegate
{
    if (!clientSocket.connected)
        return NO;
    [self registerDelegate:delegate forBuffer:CCNetworkGetSubGames];
    [clientSocket sendData:[NSData data] usingMethod:CCUdpSendMethodGuarentee CCtag:CCNetworkGetSubGames];
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
