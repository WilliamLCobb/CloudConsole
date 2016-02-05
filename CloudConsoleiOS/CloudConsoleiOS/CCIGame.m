//
//  CCGame.m
//  CloudConsole
//
//  Created by Will Cobb on 1/22/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIGame.h"
#import "AppDelegate.h"
#import "CCNetworkProtocol.h"
@interface CCIGame () {
    uint32_t pid;
}

@end

@implementation CCIGame

- (id)initWithDictionairy:(NSDictionary *)dictionairy
{
    if (self = [super init]) {
        self.hasTable = [dictionairy[@"hasTable"] boolValue];
        self.hasSettings = [dictionairy[@"hasSettings"] boolValue];
        
        self.path = dictionairy[@"path"];
        if (dictionairy[@"name"]) {
            self.name = dictionairy[@"name"];
        } else {
            self.name = [self applicationNameForPath:self.path];
        }
        if (dictionairy[@"image"]) {
            NSData *pictureData = [[NSData alloc] initWithBase64EncodedString:dictionairy[@"image"] options:0];
            self.icon = [UIImage imageWithData:pictureData];
        }
        self.subGames = [NSMutableArray new];
    }
    
    return self;
}


- (NSString *)applicationNameForPath:(NSString *)path
{
    for (NSString * component in path.pathComponents) {
        if ([component.pathExtension.lowercaseString isEqualToString:@"app"]) {
            return component.stringByDeletingPathExtension;
        }
    }
    return nil;
}

- (void)loadSubgames
{
    CCINetworkController *networkController = AppDelegate.sharedInstance.networkController;
    [networkController getSubGamesForDelegate:self];
}

- (void)CCSocket:(CCUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withTag:(uint32_t)tag
{
    if (tag == CCNetworkGetSubGames) {
        [self willChangeValueForKey:@"subGames"];
        [self.subGames removeAllObjects];
        
        NSError *error;
        NSArray *gamesArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        for (NSDictionary *gameDict in gamesArray) {
            [self.subGames addObject:[[CCIGame alloc] initWithDictionairy:gameDict]];
        }
        
        [self didChangeValueForKey:@"subGames"];
    }
}

@end
