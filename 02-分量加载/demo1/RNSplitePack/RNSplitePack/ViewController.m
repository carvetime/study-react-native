//
//  ViewController.m
//  RNSplitePack
//
//  Created by wenjie on 2019/7/31.
//  Copyright © 2019 wenjie. All rights reserved.
//

#define DEBUG 1

#import "ViewController.h"
#import <React/RCTRootView.h>

//DiffMatchPatch 中有三个文件 需要在编译阶段设置 -fno-objc-arc
#import "DiffMatchPatch.h"

@interface ViewController ()<RCTBridgeDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    RCTBridge *bridge = [[RCTBridge alloc]initWithDelegate:self launchOptions:nil];
    RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge moduleName:@"RNHighScores" initialProperties:nil];
    
    self.view = rootView;
}



- (NSString *)getMergeBundlePath{
    NSString *commonBundlePath = [[NSBundle mainBundle] pathForResource:@"common" ofType:@"bundle"];
    NSLog(@"path=%@",commonBundlePath);
    NSString *commonJsCode = [[NSString alloc] initWithContentsOfFile:commonBundlePath encoding:NSUTF8StringEncoding error:nil];
    
    
    NSString *businessBundlePath = [[NSBundle mainBundle] pathForResource:@"business" ofType:@"patch"];
    NSLog(@"path=%@",businessBundlePath);
    NSString *businessJsCode = [[NSString alloc] initWithContentsOfFile:businessBundlePath encoding:NSUTF8StringEncoding error:nil];
    
    
    DiffMatchPatch *diffMatchPatch = [[DiffMatchPatch alloc] init];
    NSArray *convertedPatches = [diffMatchPatch patch_fromText:businessJsCode error:nil];
    
    NSArray *resultsArray = [diffMatchPatch patch_apply:convertedPatches toString:commonJsCode];
    NSString *resultJSCode = resultsArray[0]; //patch合并后的js
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *newPath = [NSString stringWithFormat:@"%@/%@.bundle",docDir,@"newbusiness"];
    
    if (resultsArray.count > 1) {
        BOOL ret = [resultJSCode writeToFile:newPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"存入状态%d",ret);
    }
    return newPath;
}


- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge{
    if (DEBUG) {
        return [NSURL URLWithString:@"http://localhost:8081/index.bundle?platform=ios"];
    } else {
        NSString *path = [self getMergeBundlePath];
        NSURL *jsBundleURL = [NSURL URLWithString:path];
        return jsBundleURL;
    }
}


@end
