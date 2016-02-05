//
//  DolphinController.h
//  Dolphin
//
//  Created by Will Cobb on 1/24/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
@interface DolphinController : NSObject
/**
 * Used to reload settings and games available to the user.
 **/
- (void)reload;

/**
 * Used to populate the sub table on the phone with avaliable games returns an array of dictionairies
 **/
- (NSArray *)subGames;

/**
 * This function is responsible for launching a game and returning the application it lives in.
 * 
 * The path string passed in is equal to the path set in the dictionairy returned by subGames.
 **/
- (NSRunningApplication *)launchGameWithPath:(NSString *)path;

/**
 * Should pause the game by any means. Usually by pressing the start button
 **/
- (void)pause;



@end
