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
@interface NewDeviceTableViewController () {
    IBOutlet UITextField *deviceName;
    IBOutlet UITextField *deviceIP;
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

- (IBAction)save:(id)sender
{
    CCIDevice *newDevice = [[CCIDevice alloc] initWithName:deviceName.text host:deviceIP.text port:CCNetworkServerPort];
    NSMutableDictionary *deviceDictionairy = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Devices"] mutableCopy];
    if (!deviceDictionairy) {
        deviceDictionairy = [NSMutableDictionary new];
    }
    deviceDictionairy[deviceName.text] = [NSKeyedArchiver archivedDataWithRootObject:newDevice];
    [[NSUserDefaults standardUserDefaults] setObject:deviceDictionairy forKey:@"Devices"];
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
