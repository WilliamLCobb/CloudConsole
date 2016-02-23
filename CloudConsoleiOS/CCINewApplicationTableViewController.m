//
//  CCINewApplicationTableViewController.m
//  Cloud Console
//
//  Created by Will Cobb on 2/22/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCINewApplicationTableViewController.h"
#import "CCINetworkController.h"
#import "DALabeledCircularProgressView.h"
#import "AppDelegate.h"
#import "CCIGame.h"
@interface CCINewApplicationTableViewController () <CCINetworkControllerDelegate> {
    NSArray *addableGames;
    DALabeledCircularProgressView   *progressView;
    CCINetworkController            *networkController;
}

@end

@implementation CCINewApplicationTableViewController

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
}

- (void)viewWillAppear:(BOOL)animated
{
    networkController = AppDelegate.sharedInstance.networkController;
    [networkController registerProgressDelegate:self forBuffer:CCNetworkGetNewApplications];
    [networkController addObserver:self forKeyPath:@"addableApplications" options:NSKeyValueObservingOptionNew context:nil];
    [networkController updateAddableApplications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [networkController removeObserver:self forKeyPath:@"addableApplications"];
    networkController = nil;
}

- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"addableApplications"]) {
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
    return networkController.addableApplications.count;
}

- (CCIGame *)gameForIndexPath:(NSIndexPath *)indexPath
{
    return networkController.addableApplications[indexPath.row];
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
    //Add game
}

@end
