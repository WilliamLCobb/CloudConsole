//
//  BonjourHandler.h
//  CloudConsole
//
//  Created by Will Cobb on 1/22/15.
//  Copyright (c) 2015 Apprentice Media LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BonjourDelegate;

@interface BonjourHandler : NSObject <NSNetServiceDelegate, NSStreamDelegate, NSNetServiceBrowserDelegate>

- (id)initWithName:(NSString *)deviceName;
-(void) start;
-(void) stop;
-(void) connectToService:(NSNetService *) service;
- (void)send:(NSData *)data;
- (void)closeStreams;

@property (weak) id<BonjourDelegate> delegate;
@property (nonatomic, strong, readwrite) NSNetService *         server;
@property (nonatomic, assign, readwrite) BOOL                   isServerStarted;
@property (nonatomic, copy,   readwrite) NSString *             registeredName;
@property (nonatomic, strong, readwrite) NSInputStream *        inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *       outputStream;
@property (nonatomic, assign, readwrite) NSUInteger             streamOpenCount;
@property (nonatomic, strong, readwrite) NSMutableArray *       services;                       // of NSNetService, sorted by name
@property (nonatomic, strong, readwrite) NSNetServiceBrowser *  browser;
@end

@protocol BonjourDelegate <NSObject>

@required
- (void)bonjourHandlerConnected:(BonjourHandler *)handler;
- (void)bonjourHandlerDisconnected:(BonjourHandler *)handler;
- (void)bonjourHandler:(BonjourHandler *)handler updatedServices:(NSMutableArray *) services;
- (void)bonjourHandler:(BonjourHandler *)handler recievedData:(NSData *) data;

@end