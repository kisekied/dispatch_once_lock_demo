#README

说到单例，在Objective-C中我们很容易就能想到用`dispatch_once`来构建一个单例的对象，然而最近因为给一个目前维护的老项目增加新的功能的时候，却不小心踩到了`dispatch_once`的坑里面去了。
简单的说明一下遇到的问题：公司测试在安装完APP一段时间后，重新进入会一直黑屏闪退，并且发生时间不确定，测试的时候也只是一个机型会发生这样的情况。
当时我导出了崩溃日志，发现崩溃前是这样的（公司的项目，稍微打了一下码）：
![崩溃日志](http://upload-images.jianshu.io/upload_images/1037520-47e9cc620a31f0c0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

看到上面显示`trying to lock recursively`，说明是被死锁了。然后我注意到最靠近崩溃的符号化信息是`NBSDispatch_once`，这是某第三方监测app的库的一个方法，然后我替换了最新的SDK，发现新版本的SDK已经去除了这个方法，测试发现没再出现类似的情况，于是松了一口气，PM让发布到APP Store。

本以为这件事就这样解决了，然而在我前一天晚上发布到APP Store后，有客户反馈会出现进入不了APP的问题，但是这次跟上次的又略有不同，上面那个是打开APP后一直黑屏然后闪退，而这个是在APP加载了`Launch`界面后出现的问题。

让我们再看一下上面的崩溃日志，有一个方法`[AppViewControllerManager getAppViewControllerManager]`这个方法出现多次，`AppViewControllerManager`是负责统管整个项目试图控制器的类，而这个方法是获取这个管理类的单例对象。在该单例方法内部的`dispatch_once`里面又包含了后续执行方法，在后续执行方法中有一段会再次调用`[AppViewControllerManager getAppViewControllerManager]`，从而造成了死锁，又因为造成死锁的方法是异步网络请求，在返回结果过快的时候，第一次的`dispatch_once`的block还没有执行结束的就再次进入该`dispatch_once`的block，导致死锁。

下面让我们构造一个类似的Demo工程进行说明，为了保证出现该死锁，我们全部用同步线程执行。（注：模拟器上死锁不会crash，真机上因为系统保护机制才会强制crash）。

>编译环境：
系统: macOS 10.12
Xcode版本：8.0

我们在Demo中新建一个管理类`AppManager`，在里面添加一个单例方法：
```objc
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
```

在`AppDelegate.m`中：
```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyWindow];
    
    _manager = [AppManager getAppManager];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}
```

我们在`ViewController.m`中添加方法`doSomeThing`:
```objc
- (void)doSomeThing {
    [AppManager getAppManager];
    self.view.backgroundColor = [UIColor cyanColor];
}
```

不考虑其他因素，按步骤下来，预期屏幕背景应该是[UIColor cyanColor]；
然而实际运行结果是:
![运行结果](http://upload-images.jianshu.io/upload_images/1037520-3a41592f3526a7c9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们查看运行的堆栈信息：
![堆栈信息](http://upload-images.jianshu.io/upload_images/1037520-7979787633b72de6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


发现app进程停在`[ViewController doSomeThing]`中，并且在调用了`[AppManager getAppManager]`后进入信号等待，因为此时`[AppManager getAppManager]`中`dispatch_once`的block并未执行完成，处于`lock`状态，等待完全执行完成该block，而在该block中又进行了一次`[AppManager getAppManager]`的调用，从而造成死锁。

我们注释掉`[ViewController doSomeThing]`中的`[AppManager getAppManager];`后发现背景色如期变成[UIColor cyanColor]:
![如期运行](http://upload-images.jianshu.io/upload_images/1037520-4303d17a1b4fb7bd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

如何避免这类问题的发生？
>1.慎用单例模式;
2.在`dispacth_once`包裹的block中，尽量避免与其他类的耦合。

推荐写法：

将`dispatch_once`中与其他类耦合的地方移出：

```objc
+ (AppManager *)getAppManager {
    static AppManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[AppManager alloc] init];
    });
    return manager;
}
```
放置到完全执行完初始化单例的后续方位执行：

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyWindow];
    
    _manager = [AppManager getAppManager];
    
    ViewController *vc = [[ViewController alloc] init];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    window.rootViewController = vc;
    [vc doSomeThing];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}
```

以上是该次问题的总结，欢迎大家指教。




