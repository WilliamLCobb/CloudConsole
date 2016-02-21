//
//  CCIGameSelectionTableViewController.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/23/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIAppSelectionTableViewController.h"

#import "AppDelegate.h"
#import "CCIGame.h"

#import "CCIGameSelectionTableViewController.h"
#import "DALabeledCircularProgressView.h"

@interface CCIAppSelectionTableViewController () {
    CCIGame                 *selectedGame;
    CCINetworkController    *networkController;
    DALabeledCircularProgressView *progressView;
    
    BOOL currentView;
}

@end

@implementation CCIAppSelectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
    
//    UILabel *searchingLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, self.view.frame.size.width - 40, 20)];
//    searchingLabel.text = @"Loading Applications";
//    searchingLabel.textAlignment = NSTextAlignmentCenter;
//    [self.tableView.tableFooterView addSubview:searchingLabel];
    
    progressView = [[DALabeledCircularProgressView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 60, 10, 120, 120)];
    progressView.progressLabel.text = @"Loading...";
    progressView.progressTintColor = kAppColor;
    progressView.thicknessRatio = 0.11;
    progressView.roundedCorners = 5;
    [self.tableView.tableFooterView addSubview:progressView];
    
    currentView = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate.sharedInstance.forcePortrait = YES;
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIInterfaceOrientationPortrait] forKey:@"orientation"];
    if (!AppDelegate.sharedInstance.networkController.isConnected) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        networkController = AppDelegate.sharedInstance.networkController;
        [networkController registerProgressDelegate:self forBuffer:CCNetworkGetAvaliableGames];
        [networkController addObserver:self forKeyPath:@"games" options:NSKeyValueObservingOptionNew context:nil];
        [networkController updateAvaliableGames];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    currentView = NO;
    [networkController removeObserver:self forKeyPath:@"games"];
    networkController = nil;
}

- (void)pingDevices
{
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"games"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{
                self.tableView.tableFooterView.alpha = 0;
            } completion:^(BOOL finished) {
                [self.tableView reloadData];
                self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
            }];
        });
    } else {
        NSLog(@"Unknown keypath: %@", keyPath);
    }
}

- (void)downloadProgress:(float)progress forTag:(uint32_t)tag
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [progressView setProgress:progress animated:YES];
    });
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return networkController.games.count;
}

- (CCIGame *)gameForIndexPath:(NSIndexPath *)indexPath
{
    return networkController.games[indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"game"];
    
    CCIGame *game = [self gameForIndexPath:indexPath];
    cell.imageView.image = game.icon;
    cell.textLabel.text = game.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    CCIGame *game = [self gameForIndexPath:indexPath];
    if (game.hasTable) {
        selectedGame = game;
        [self performSegueWithIdentifier:@"ToGames" sender:self];
    } else {
        NSLog(@"Name: %@", game.name);
        [AppDelegate.sharedInstance launchGame:game];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ToGames"]) {
        CCIGameSelectionTableViewController *destination = segue.destinationViewController;
        destination.currentGame = selectedGame;
    }
}

@end
