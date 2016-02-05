//
//  ServerBroadcaster.h
//  CloudConsole
//
//  Created by Will Cobb on 1/30/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BonjourHandler.h"
#import "CCUdpSocket.h"

@interface CCOServerBroadcaster : NSObject <BonjourDelegate, CCUdpSocketDelegate>

- (void)startBroadcastWithName:(NSString *)name;
- (void)stop;

@end
