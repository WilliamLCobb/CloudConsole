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

@protocol CCINetworkDelegate <NSObject>

- (void)receivedData:(NSData *)data fromBuffer:(uint32_t) buffer;

@end

@interface CCINetworkController : NSObject <CCUdpSocketDelegate>

@property (weak) CCIMainViewController  *mainViewController;

@property (nonatomic) NSMutableArray    *games;
@property (nonatomic) NSMutableDictionary *socketDelegates;

- (id)initWithHost:(NSString *)host port:(uint16_t)port;
- (CCIStreamManager *)startStreamWithGame:(CCIGame *)game;

- (void)setDelegate:(id <CCINetworkDelegate>)delegate forBuffer:(uint32_t)buffer;
- (void)updateAvaliableGames;
- (void)getSubGamesForDelegate:(id<CCINetworkDelegate>)delegate;


@end
