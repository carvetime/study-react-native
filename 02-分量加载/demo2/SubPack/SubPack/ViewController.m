//
//  ViewController.m
//  SubPack
//
//  Created by wenjie on 2019/8/12.
//  Copyright © 2019 wenjie. All rights reserved.
//
#import <React/RCTExceptionsManager.h>
#import <React/RCTRootView.h>

#import "ViewController.h"

@interface ViewController ()<RCTBridgeDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    RCTBridge *bridge = [[RCTBridge alloc]initWithDelegate:self launchOptions:nil];
    RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge moduleName:@"RNHighScores" initialProperties:nil];
    
    self.view = rootView;
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
    return  [NSURL URLWithString:@"http://localhost:8081/index.bundle?platform=ios"];
}

- (void)loadSourceForBridge:(RCTBridge *)bridge withBlock:(RCTSourceLoadBlock)loadCallback{
    [RCTJavaScriptLoader loadBundleAtURL:[NSURL URLWithString:@"http://localhost:8081/index.bundle?platform=ios"] onProgress:^(RCTLoadingProgress *progressData) {

    } onComplete:^(NSError *error, RCTSource *source) {
        loadCallback(nil,source);
    }];
}

@end
