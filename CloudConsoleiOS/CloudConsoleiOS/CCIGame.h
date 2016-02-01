//
//  CCGame.h
//  CloudConsole
//
//  Created by Will Cobb on 1/22/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CCINetworkController.h"
@interface CCIGame : NSObject <CCINetworkDelegate>

@property (strong)  NSString    *path;
@property (strong)  NSString    *name;
@property (strong)  UIImage     *icon;

@property BOOL                  hasTable;
@property BOOL                  hasSettings;

@property NSMutableArray        *subGames;

- (id)initWithDictionairy:(NSDictionary *)dictionairy;
- (void)loadSubgames;
@end
