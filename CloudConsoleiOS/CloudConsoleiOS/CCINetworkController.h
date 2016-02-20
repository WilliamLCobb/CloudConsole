//
//  CCINetworkController.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/11/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
//  http://stackoverflow.com/questions/11621553/how-to-use-gcdasyncudpsocket-for-multicast-over-wifi-and-bluetooth

#import <Foundation/Foundation.h>
#import "CCUdpSocket.h"
#import "CCIStreamManager.h"

@class CCIMainViewController;
@class CCIStreamManager;
@class CCIGame;

@protocol CCINetworkControllerDelegate <NSObject>

@optional
- (void)connectedToServer;
- (void)disconnectedFromServer;
- (void)downloadProgress:(float)progress forTag:(uint32_t)tag;
@end


@interface CCINetworkController : NSObject <CCUdpSocketDelegate, CCIStreamManagerDelegate>

@property (weak) id <CCINetworkControllerDelegate>  delegate;

@property (nonatomic) NSMutableArray    *games;

- (id)initWithHost:(NSString *)host port:(uint16_t)port;
- (CCIStreamManager *)startStreamWithGame:(CCIGame *)game;


- (BOOL)registerDelegate:(id <CCUdpSocketDelegate>)delegate forBuffer:(uint32_t)bufferTag;
- (BOOL)registerProgressDelegate:(id<CCINetworkControllerDelegate>)delegate forBuffer:(uint32_t)abuffer;
- (BOOL)updateAvaliableGames;
- (BOOL)getSubGamesForDelegate:(id<CCUdpSocketDelegate>)delegate;
- (void)pingHost:(NSString *)host;
- (BOOL)isConnected;

@end
