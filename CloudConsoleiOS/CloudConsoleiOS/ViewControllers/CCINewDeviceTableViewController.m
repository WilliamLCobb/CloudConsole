//
//  NewDeviceTableViewController.m
//  Cloud Console
//
//  Created by Will Cobb on 2/4/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCINewDeviceTableViewController.h"
#import "CCNetworkProtocol.h"

#include <arpa/inet.h>

@interface CCINewDeviceTableViewController () {
    IBOutlet UITextField    *deviceName;
    IBOutlet UITextField    *deviceIP;
    IBOutlet UIBarButtonItem    *saveButton;
    
    IBOutlet UIButton       *deleteButton;
}

@end

@implementation CCINewDeviceTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.currentDevice) {
        deviceName.text = self.currentDevice.name;
        deviceIP.text   = self.currentDevice.host;
        saveButton.enabled = YES;
    }
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
    NSMutableDictionary *deviceDictionairy = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Devices"] mutableCopy];
    if (!deviceDictionairy) {
        deviceDictionairy = [NSMutableDictionary new];
    }
    CCIDevice *newDevice;
    if (self.currentDevice) {
        [deviceDictionairy removeObjectForKey:self.currentDevice.name]; // Delete old
        self.currentDevice.name = deviceName.text;
        self.currentDevice.host = deviceIP.text;
        newDevice = self.currentDevice;
    } else {
        newDevice = [[CCIDevice alloc] initWithName:deviceName.text
                                                    deviceName:@"mac"
                                                          host:deviceIP.text
                                                          port:CCNetworkServerPort
                                                  discoverType:CCIDeviceDiscoverTypeFavorite];
    }
    
    //Save
    deviceDictionairy[deviceName.text] = [NSKeyedArchiver archivedDataWithRootObject:newDevice];
    [[NSUserDefaults standardUserDefaults] setObject:deviceDictionairy forKey:@"Devices"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)deleteDevice:(id)sender
{
    NSMutableDictionary *deviceDictionairy = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Devices"] mutableCopy];
    [deviceDictionairy removeObjectForKey:self.currentDevice.name]; // Delete old
    [[NSUserDefaults standardUserDefaults] setObject:deviceDictionairy forKey:@"Devices"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2 + (self.currentDevice != nil);
}

-(BOOL)shouldAutorotate {
    return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
}

@end
