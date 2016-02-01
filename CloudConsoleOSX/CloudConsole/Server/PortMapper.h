/*

File: PortMapper.h


//  Created by Will Cobb on 3/11/14.
//  Copyright (c) 2014 Will Cobb. All rights reserved.
//
*/
//https://github.com/mugginsoft/Cocoa-PortMapper/blob/master/main.m

#import <Foundation/Foundation.h>
#import <CoreFoundation/CFSocket.h>


/*  PortMapper attempts to make a particular network port on this computer publicly reachable
    for incoming connections, by "opening a hole" through a Network Address Translator 
    (NAT) or firewall that may be in between the computer and the public Internet.
 
    The port mapping may fail if:
    * the NAT/router/firewall does not support either the UPnP or NAT-PMP protocols;
    * the device doesn't implement the protocols correctly (this happens);
    * the network administrator has disabled port-mapping;
    * there is a second layer of NAT/firewall (this happens in some ISP networks.)
 
    The PortMapper is asynchronous. It will take a nonzero amount of time to set up the
    mapping, and the mapping may change in the future as the network configuration changes.
    To be informed of changes, either use key-value observing to watch the "error",
    "publicAddress" and "publicPort" properties, or observe the PortMapperChangedNotification.
 
    Typical usage is to:
    * Start a network service that listens for incoming connections on a port
    * Open a PortMapper
    * When the PortMapper reports the public address and port of the mapping, you somehow
      notify other peers of that address and port, so they can connect to you.
    * When the PortMapper reports changes, you (somehow) notify peers of the changes.
    * When closing the network service, close the PortMapper object too.
*/ 
@interface PortMapper : NSObject
{
    UInt16 _port, _desiredPublicPort, _publicPort;
    BOOL _mapTCP, _mapUDP;
    SInt32 _error;
    void* /*DNSServiceRef*/ _service; // Typed void* to avoid having to #include <dnssd.h> in this header
    CFSocketRef _socket;
    CFRunLoopSourceRef _socketSource;
    UInt32 _rawPublicAddress;
    NSString *_publicAddress;
}

/** Initializes a PortMapper that will map the given local (private) port.
    By default it will map TCP and not UDP, and will not suggest a desired public port,
    but this can be configured by setting properties before opening the PortMapper.
 */
- (id) initWithPort: (UInt16)port;

/** Should the TCP or UDP port, or both, be mapped? By default, TCP only.
    These properties have no effect if changed while the PortMapper is open. */
@property BOOL mapTCP, mapUDP;

/** You can set this to the public port number you'd like to get.
    It defaults to 0, which means "no preference".
    This property has no effect if changed while the PortMapper is open. */
@property UInt16 desiredPublicPort;

/** Opens the PortMapper, using the current settings of the above properties.
    Returns immediately; you can find out when the mapping is created or fails
    by observing the error/publicAddress/publicPort properties, or by listening
    for the PortMapperChangedNotification.
    It's very unlikely that this call will fail (return NO). If it does, it
    probably means that the mDNSResponder process isn't working. */
- (BOOL) open;


/** Blocks till the PortMapper finishes opening. Returns YES if it opened, NO on error.
    It's not usually a good idea to use this, as it will lock up your application
    until a response arrives from the NAT. Listen for asynchronous notifications instead.
    If called when the PortMapper is closed, it will call -open for you.
    If called when it's already open, it just returns YES. */
- (BOOL) waitTillOpened;

/** Closes the PortMapper, terminating any open port mapping. */
- (void) close;

/** The following properties are valid only while the PortMapper is open.
    They are all KV-observable, or you can listen for a PortMapperChangedNotification.
    If error is nonzero, none of the other properties are valid (they'll all be zero/nil.) */
@property (readonly) SInt32 error;                  // Really DNSServiceErrorType
@property (readonly) UInt32 rawPublicAddress;       // IPv4 addr in network byte order (big-endian)
@property (readonly,copy) NSString* publicAddress;  // IPv4 dotted-quad string
@property (readonly) unsigned short publicPort;

/** Returns YES if a non-null port mapping is in effect: 
    that is, if the public address differs from the local one. */
@property (readonly) BOOL isMapped;


// UTILITY CLASS METHODS:


/** Determine the main interface's public IP address, without mapping any ports. */
+ (NSString*) findPublicAddress;

/** Returns this computer's local IPv4 address. */
+ (NSString*) localAddress;
+ (UInt32) rawLocalAddress;

/** Is +localAddress in a private address range (like 10.0.1.X)? */
+ (BOOL) localAddressIsPrivate;

@end


/** This notification is posted asynchronously when the status of a PortMapper
    (its error, publicAddress or publicPort) changes. */
extern NSString* const PortMapperChangedNotification;
