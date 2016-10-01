//
//  AppManager.m
//  Dispatch_once_lock_demo
//
//  Created by kisekied on 2016/10/1.
//  Copyright © 2016年 kisekied. All rights reserved.
//

#import "AppManager.h"
#import "ViewController.h"
#import "AppDelegate.h"

@implementation AppManager

+ (AppManager *)getAppManager {
    static AppManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[AppManager alloc] init];
        
        ViewController *vc = [[ViewController alloc] init];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        window.rootViewController = vc;
        [vc doSomeThing];
    });
    return manager;
}

@end
