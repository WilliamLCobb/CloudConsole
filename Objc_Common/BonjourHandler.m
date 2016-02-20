//
//  BonjourHandler.m
//  iMouseiOS
//
//  Created by Will Cobb on 1/22/15.
//  Copyright (c) 2015 Apprentice Media LLC. All rights reserved.
//

#import "BonjourHandler.h"

static NSString * kCCBonjourType = @"_CloudConsole._tcp.";

@implementation BonjourHandler


-(id) initWithName:(NSString *)deviceName
{
    if ((self = [super init]))
    {
        self.server = [[NSNetService alloc] initWithDomain:@"local." type:kCCBonjourType name:deviceName port:0];
        self.server.includesPeerToPeer = YES;
        [self.server setDelegate:self];
        [self.server publishWithOptions:NSNetServiceListenForConnections];
        self.isServerStarted = YES;
        
        self.services = [NSMutableArray new];
        
        [self setupForNewConnection];
    }
    return self;
}

- (void)setupForNewConnection
{
    
    [self closeStreams];
    
    // If our server is deregistered, reregister it.
    
    if (!self.isServerStarted) {
        [self.server publishWithOptions:NSNetServiceListenForConnections];
        self.isServerStarted = YES;
    }
    
}

- (void)start
{
    NSLog(@"Bonjour Starting");
    assert([self.services count] == 0);
    
    assert(self.browser == nil);
    
    self.browser = [[NSNetServiceBrowser alloc] init];
    self.browser.includesPeerToPeer = YES;
    [self.browser setDelegate:self];
    [self.browser searchForServicesOfType:kCCBonjourType inDomain:@"local"];
}

- (void)stop
{
    NSLog(@"Bonjour Stopping");
    [self.browser stop];
    self.browser = nil;
    
    [self.server stop];
    //[self.server stopMonitoring];
    self.server = nil;
    
    self.registeredName = nil;
    
    
    [self.services removeAllObjects];
    [self closeStreams];
    NSLog(@"Bonjour stopped");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    assert(browser == self.browser);
#pragma unused(browser)
    assert(service != nil);
    
    // Remove the service from our array (assume it's there, of course).
    
    if ( ! [self.server isEqual:service] ) {
        [self.services removeObject:service];
    }
    
    // Only update the UI once we get the no-more-coming indication.
    
    //if ( ! moreComing ) {
        [self.delegate bonjourHandler:self updatedServices:self.services];
    //}
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    assert(browser == self.browser);
#pragma unused(browser)
    assert(service != nil);
    
    // Add the service to our array (unless its our own service).
    
    if ( ! [self.server isEqual:service] ) {
        [self.services addObject:service];
    }
    
    // Only update the UI once we get the no-more-coming indication.
    
    //if ( ! moreComing ) {
        [self.delegate bonjourHandler:self updatedServices:self.services];
    //}
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)errorDict
{
    NSLog(@"Errw %@", errorDict);
    assert(browser == self.browser);
    assert(errorDict != nil);
    //assert(NO);         // The usual reason for us not searching is a programming error.
}

- (void)connectToService:(NSNetService *)service
// Called by the picker when the user has chosen a service for us to connect to.
// The picker is already displaying its connection-in-progress UI.
{
    if (self.streamOpenCount != 0) {
        NSLog(@"Warining, trying to connect to a service but we're already connected");
        [self closeStreams];
    }
    NSLog(@"Connecting to %@", service.name);
    BOOL                success;
    NSInputStream *     inStream;
    NSOutputStream *    outStream;
    assert(service != nil);
    
    
    // Create and open streams for the service.
    //
    // -getInputStream:outputStream: just creates the streams, it doesn't hit the
    // network, and thus it shouldn't fail under normal circumstances (in fact, its
    // CFNetService equivalent, CFStreamCreatePairWithSocketToNetService, returns no status
    // at all).  So, I didn't spend too much time worrying about the error case here.  If
    // we do get an error, you end up staying in the picker.  OTOH, actual connection errors
    // get handled via the NSStreamEventErrorOccurred event.
    
    success = [service getInputStream:&inStream outputStream:&outStream];
    if ( ! success ) {
        NSLog(@"Unable to connect");
        [self setupForNewConnection];
        assert(self.inputStream == nil);
        assert(self.outputStream == nil);
    } else {
        self.inputStream  = inStream;
        self.outputStream = outStream;
        
        [self openStreams];
    }
}

- (void)cancelConnect
// Called by the picker when the user taps the Cancel button in its
// connection-in-progress UI.  We respond by closing our in-progress connection.
{
    NSLog(@"Cancel Connect");
    [self closeStreams];
}

- (void)send:(NSData *)data
{
    if (!(self.streamOpenCount == 2)) {
        NSLog(@"Warning, stream open count: %lu", (unsigned long)self.streamOpenCount);
        return;
    }
    
    // Only write to the stream if it has space available, otherwise we might block.
    // In a real app you have to handle this case properly but in this sample code it's
    // OK to ignore it; if the stream stops transferring data the user is going to have
    // to tap a lot before we fill up our stream buffer (-:
    
    if ( [self.outputStream hasSpaceAvailable] ) {
        NSInteger   bytesWritten;
        bytesWritten = [self.outputStream write:[data bytes] maxLength:[data length]];
        if (bytesWritten != [data length]) {
            NSLog(@"dsa");
            //[self setupForNewConnection];
        }
    }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    switch(eventCode) {
        case NSStreamEventOpenCompleted: {
            self.streamOpenCount += 1;
            //assert(self.streamOpenCount <= 2);
            if (self.streamOpenCount == 1)
                [self.delegate bonjourHandlerConnected:self];
            
            else if (self.streamOpenCount == 2) {
                [self.server stop];
                self.isServerStarted = NO;
                self.registeredName = nil;
            }
        } break;
            
        case NSStreamEventHasSpaceAvailable: {
            if (stream != self.outputStream) {
                NSLog(@"Bonjour Error: NSStreamEventHasSpaceAvailable not self.outputStream");
            }
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"Reading bytes");
            uint8_t    data[1024];
            NSInteger  bytesRead;
            
            if (stream != self.inputStream) {
                NSLog(@"Bonjour Error: NSStreamEventHasBytesAvailable not self.inputStream");
            }
            bytesRead = [self.inputStream read:data maxLength:1024];
            if (bytesRead <= 0) {
                // Do nothing; we'll handle EOF and error in the
                // NSStreamEventEndEncountered and NSStreamEventErrorOccurred case,
                // respectively.
                
            } else {
                [self.delegate bonjourHandler:self recievedData:[[NSData alloc] initWithBytes:data length:bytesRead]];
                //NSLog(@"Recieved Data %@", stringFromData);
            }
        } break;
            
        default:
            //assert(NO);
            // fall through
        case NSStreamEventErrorOccurred: {
        }
            // fall through
        case NSStreamEventEndEncountered: {
            [self setupForNewConnection];
            [self.delegate bonjourHandlerConnected:self];
        } break;
    }
}

- (void)openStreams
{
    assert(self.inputStream != nil);            // streams must exist but aren't open
    assert(self.outputStream != nil);
    if (self.streamOpenCount != 0) {
        NSLog(@"Tried to open a second stream");
        return;
    }
    assert(self.streamOpenCount == 0);
    
    [self.inputStream  setDelegate:self];
    [self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream  open];
    
    [self.outputStream setDelegate:self];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
}

- (void)closeStreams
{
    assert( (self.inputStream != nil) == (self.outputStream != nil) );      // should either have both or neither
    if (self.inputStream != nil) {
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream close];
        self.inputStream = nil;
        
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream close];
        self.outputStream = nil;
    }
    self.streamOpenCount = 0;
}


#pragma mark - QServer delegate

- (void)netServiceDidPublish:(NSNetService *)sender
{
    assert(sender == self.server);
    NSLog(@"Bonjour Published");
    self.registeredName = self.server.name;
}

- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    // Due to a bug <rdar://problem/15626440>, this method is called on some unspecified
    // queue rather than the queue associated with the net service (which in this case
    // is the main queue).  Work around this by bouncing to the main queue.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        assert(sender == self.server);
        assert(inputStream != nil);
        assert(outputStream != nil);
        
        assert( (self.inputStream != nil) == (self.outputStream != nil) );      // should either have both or neither
        
        if (/* DISABLES CODE */ (NO) && self.inputStream != nil) {
            // We already have a game in place; reject this new one.
            [inputStream open];
            [inputStream close];
            [outputStream open];
            [outputStream close];
        } else {
            // Start up the new game.  Start by deregistering the server, to discourage
            // other folks from connecting to us (and being disappointed when we reject
            // the connection).
            
            [self.server stop];
            self.isServerStarted = NO;
            self.registeredName = nil;
            
            // Latch the input and output sterams and kick off an open.
            
            self.inputStream  = inputStream;
            self.outputStream = outputStream;
            
            [self openStreams];
        }
    }];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
// This is called when the server stops of its own accord.  The only reason
// that might happen is if the Bonjour registration fails when we reregister
// the server, and that's hard to trigger because we use auto-rename.  I've
// left an assert here so that, if this does happen, we can figure out why it
// happens and then decide how best to handle it.
{
    NSLog(@"Hard Stop");
    NSLog(@"Errc %@", errorDict);
    assert(sender == self.server);
    //assert(NO);
}

@end
