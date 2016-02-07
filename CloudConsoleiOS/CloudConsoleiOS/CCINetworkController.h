//
//  CCINetworkController.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/11/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCUdpSocket.h"

@class CCIMainViewController;
@class CCIStreamManager;
@class CCIGame;

@interface CCINetworkController : NSObject <CCUdpSocketDelegate>

@property (weak) CCIMainViewController  *mainViewController;

@property (nonatomic) NSMutableArray    *games;

- (id)initWithHost:(NSString *)host port:(uint16_t)port;
- (CCIStreamManager *)startStreamWithGame:(CCIGame *)game;


- (BOOL)registerDelegate:(id <CCUdpSocketDelegate>)delegate forBuffer:(uint32_t)bufferTag;
- (BOOL)updateAvaliableGames;
- (BOOL)getSubGamesForDelegate:(id<CCUdpSocketDelegate>)delegate;
- (void)pingHost:(NSString *)host;
- (BOOL)isConnected;

@end
