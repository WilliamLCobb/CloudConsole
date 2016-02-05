//
//  CCGame.h
//  CloudConsole
//
//  Created by Will Cobb on 1/22/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
@interface CCGame : NSObject

@property (strong)  NSString    *path;
@property (strong)  NSString    *name;
@property (strong)  NSImage     *icon;
+(NSArray <CCGame *> *)gamesAtPaths:(NSArray *)plusPaths;
+(NSArray <NSString *> *)defaultPaths;

- (id)initWithPath:(NSString *)path;
- (NSData *)dataRepresentation;

+(NSString *)applicationNameForPath:(NSString *)path;
@end
