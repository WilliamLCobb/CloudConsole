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
@property BOOL running;
+(NSArray <CCGame *> *)gamesAtPaths:(NSArray *)plusPaths;
+(NSArray <CCGame *> *)allApplicationsAtPath:(NSString *)path;
+(NSArray <NSString *> *)defaultPaths;
+(NSString *)applicationNameForPath:(NSString *)path;
+(NSString *)processPathFromPid:(pid_t)apid;

- (id)initWithPath:(NSString *)path;
- (NSDictionary *)dataRepresentation;


@end
