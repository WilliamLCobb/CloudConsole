//
//  CCIGameSelectionTableViewController.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/27/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIGameSelectionTableViewController.h"
#import "AppDelegate.h"
#import "CCIStreamViewController.h"
#import "CCNetworkProtocol.h"

@interface CCIGameSelectionTableViewController () {
    BOOL gamesLoaded;
}

@end

@implementation CCIGameSelectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.currentGame addObserver:self forKeyPath:@"subGames" options:NSKeyValueObservingOptionNew context:nil];
    [self.currentGame loadSubgames];
    
    // Set up loading text
    self.tableView.tableFooterView = [UIView new];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
    
    UILabel *searchingLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, self.view.frame.size.width - 40, 20)];
    searchingLabel.text = @"Loading Games";
    searchingLabel.textAlignment = NSTextAlignmentCenter;
    [self.tableView.tableFooterView addSubview:searchingLabel];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activity startAnimating];
    activity.frame = CGRectMake(self.view.frame.size.width/2 - activity.frame.size.width/2, searchingLabel.frame.size.height + 20, activity.frame.size.width, activity.frame.size.height);
    [self.tableView.tableFooterView addSubview:activity];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!AppDelegate.sharedInstance.networkController.isConnected) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"subGames"]) {
        [self.tableView reloadData];
        if (!gamesLoaded) {
            gamesLoaded = YES;
            self.tableView.tableFooterView = [UIView new];
        }
        
    } else {
        NSLog(@"Unknown keypath: %@", keyPath);
    }
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
    return self.currentGame.subGames.count;
}

- (CCIGame *)gameForIndexPath:(NSIndexPath *)indexPath
{
    return self.currentGame.subGames[indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"game"];
    
    CCIGame *game = [self gameForIndexPath:indexPath];
    //cell.imageView.image = game.icon;
    cell.textLabel.text = game.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    CCIGame *game = [self gameForIndexPath:indexPath];
    
    CCIStreamManager *streamManager = [AppDelegate.sharedInstance.networkController startStreamWithGame:game];
    CCIStreamViewController *streamViewController = (CCIStreamViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CCIStreamViewController"];
    streamViewController.streamManager = streamManager;
    
    streamManager.outputDelegate = streamViewController;
    [self presentViewController:streamViewController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self.currentGame removeObserver:self forKeyPath:@"subGames"];
}

@end
