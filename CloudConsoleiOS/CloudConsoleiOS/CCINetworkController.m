//
//  CCINetworkController.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/11/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

// Communication will be done over TCP
// Streaming will be done over UDP
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
}

@end

@implementation CCINetworkController

- (id)initWithHost:(NSString *)host port:(uint16_t)port
{
    if (self = [super init]) {
        self.socketDelegates = [NSMutableDictionary dictionary];
        clientSocket = [[CCUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        //clientSocket = [[CCUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
        //socketQueue = dispatch_queue_create("Socket Queue", NULL);
        //clientSocket = [[CCUdpSocket alloc] initWithDelegate:self delegateQueue:socketQueue];// socketQueue:socketQueue];
        
        [clientSocket setDestinationHost:host Port:port]; //

        NSLog(@"Connected to server");
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
    [clientSocket sendData:sendData withTimeout:-1 CCtag:CCNetworkOpenStream];
    return streamManager;
}

- (void)portMapChanged: (NSNotification*)n
{
    NSLog(@"Port is open on ip:%@, port: %hu", portMapper.publicAddress, portMapper.publicPort);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    uint32_t *message = (uint32_t *)data.bytes;
    switch (message[0]) {
        case CCNetworkGetAvaliableGames:
        {
            [self willChangeValueForKey:@"games"];
            self.games = [NSMutableArray new];
            
            NSError *error;
            NSArray *gamesArray = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytesNoCopy:(uint8_t *)data.bytes+4 length:data.length-4 freeWhenDone:NO] options:0 error:&error];
            
            for (NSDictionary *gameDict in gamesArray) {
                [self.games addObject:[[CCIGame alloc] initWithDictionairy:gameDict]];
            }
            
            [self didChangeValueForKey:@"games"];
            break;
        }
            
        default:
        {
            NSString *bufferTag = [NSString stringWithFormat:@"%u", message[0]];
            id <CCINetworkDelegate> delegate = [self.socketDelegates objectForKey:bufferTag];
            if (delegate) {
                [delegate receivedData:[NSData dataWithBytesNoCopy:(uint8_t*)data.bytes+4
                                                            length:data.length-4
                                                      freeWhenDone:NO]
                            fromBuffer:message[0]];
                return;
            }
            NSLog(@"CCINetworkController got unknown tag: %d", message[0]);
            break;
        }
    }
}

- (void)wrongApplicationState
{
    NSLog(@"Socket client not in home state");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Calls To Server
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setDelegate:(id<CCINetworkDelegate>)delegate forBuffer:(uint32_t)abuffer
{
    NSString *bufferTag = [NSString stringWithFormat:@"%u", abuffer];
    // Hopefully this works
    __weak id weakDel = delegate;
    self.socketDelegates[bufferTag] = weakDel;
}

- (void)updateAvaliableGames
{
    [clientSocket sendData:[NSData data] withTimeout:-1 CCtag:CCNetworkGetAvaliableGames];
}

- (void)getSubGamesForDelegate:(id<CCINetworkDelegate>)delegate
{
    [self setDelegate:delegate forBuffer:CCNetworkGetSubGames];
    [clientSocket sendData:[NSData data] withTimeout:-1 CCtag:CCNetworkGetSubGames];
}

- (void)dealloc
{
    [clientSocket setDestinationHost:nil Port:0]; //Debug this and find out why the socket is not being deallocated
    NSLog(@"CCINetwork successfully deallocated");
}

@end
