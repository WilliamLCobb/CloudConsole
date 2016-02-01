//
//  ViewController.m
//  CloudConsole
//
//  Created by Will Cobb on 1/5/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "MainViewController.h"
#import "CCOServer.h"
#import "CCNetworkProtocol.h"
@interface MainViewController() {
}

@end
@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewDidAppear {
    self.view.window.movableByWindowBackground  = YES;
    self.view.window.titlebarAppearsTransparent = YES;
    self.view.window.styleMask |= NSFullSizeContentViewWindowMask;

    
    NSVisualEffectView *vibrant=[[NSVisualEffectView alloc] initWithFrame:self.view.bounds];
    [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    // uncomment for dark mode instead of light mode
    // [vibrant setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
    [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
    [self.view addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
    // Do any additional setup after loading the view.

}



- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
