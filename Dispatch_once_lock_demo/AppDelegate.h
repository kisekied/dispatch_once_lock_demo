//
//  AppDelegate.h
//  Dispatch_once_lock_demo
//
//  Created by kisekied on 2016/10/1.
//  Copyright © 2016年 kisekied. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AppManager;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) AppManager *manager;

@end

