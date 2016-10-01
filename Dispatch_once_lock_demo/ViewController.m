//
//  ViewController.m
//  Dispatch_once_lock_demo
//
//  Created by kisekied on 2016/10/1.
//  Copyright © 2016年 kisekied. All rights reserved.
//

#import "ViewController.h"
#import "AppManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)doSomeThing {
    
    [AppManager getAppManager];
    self.view.backgroundColor = [UIColor cyanColor];
}



@end
