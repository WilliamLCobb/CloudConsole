//
//  NewDeviceTableViewController.m
//  Cloud Console
//
//  Created by Will Cobb on 2/4/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "NewDeviceTableViewController.h"
#import "CCIDevice.h"
#import "CCNetworkProtocol.h"

#include <arpa/inet.h>

@interface NewDeviceTableViewController () {
    IBOutlet UITextField    *deviceName;
    IBOutlet UITextField    *deviceIP;
    IBOutlet UIBarButtonItem    *saveButton;
}

@end

@implementation NewDeviceTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)textChanged:(id)sender
{
    if (deviceName.text.length > 0 && [self isValidIPAddress:deviceIP.text]) {
        saveButton.enabled = YES;
    } else {
        saveButton.enabled = NO;
    }
}

- (BOOL)isValidIPAddress:(NSString *)string
{
    const char *utf8 = [string UTF8String];
    int success;
    
    struct in_addr dst;
    success = inet_pton(AF_INET, utf8, &dst);
    if (success != 1) {
        struct in6_addr dst6;
        success = inet_pton(AF_INET6, utf8, &dst6);
    }
    
    return success == 1;
}

- (IBAction)save:(id)sender
{
    NSString *name = [NSString stringWithFormat:@"mac.%@", deviceName.text];
    CCIDevice *newDevice = [[CCIDevice alloc] initWithName:name host:deviceIP.text port:CCNetworkServerPort];
    NSMutableDictionary *deviceDictionairy = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Devices"] mutableCopy];
    if (!deviceDictionairy) {
        deviceDictionairy = [NSMutableDictionary new];
    }
    deviceDictionairy[deviceName.text] = [NSKeyedArchiver archivedDataWithRootObject:newDevice];
    [[NSUserDefaults standardUserDefaults] setObject:deviceDictionairy forKey:@"Devices"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)shouldAutorotate {
    return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
}

@end
