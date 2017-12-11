//
//  AppDelegate.m
//  TestPushNotifacation
//
//  Created by wangmiao on 2017/12/4.
//  Copyright © 2017年 wangmiao. All rights reserved.
//
// 引入JPush功能所需头文件
#import "JPUSHService.h"
// iOS10注册APNs所需头文件
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif
// 如果需要使用idfa功能所需要引入的头文件（可选）
#import <AdSupport/AdSupport.h>
//  语音播报
#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"

@interface AppDelegate ()<JPUSHRegisterDelegate>{
    SystemSoundID _soundFileObject;
}
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@end

@implementation AppDelegate

//  播放音频文件
- (void)playMusic:(NSString *)name type:(NSString *)type {
    //得到音效文件的地址
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:name ofType:type];
    
    //将地址字符串转换成url
    NSURL *soundURL = [NSURL fileURLWithPath:soundFilePath];
    
    //生成系统音效id
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &_soundFileObject);
    
    //播放系统音效
    AudioServicesPlaySystemSound(_soundFileObject);
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    //Required
    //notice: 3.0.0及以后版本注册可以这样写，也可以继续用之前的注册方式
    // !!!: 注册极光推送
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        //  iOS 10.0以上走推送扩展，声音由文字合成语音，不需要UNAuthorizationOptionSound
        JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
        entity.types = UNAuthorizationOptionAlert | UNAuthorizationOptionBadge;
        [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
    } else if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        //  iOS 10.0以下需要设置UIUserNotificationTypeSound，通过后台的sound来播放本地音频文件
        [JPUSHService registerForRemoteNotificationTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert categories:nil];
    } else {
        //categories 必须为nil
        [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
    }
    // Optional
    // 获取IDFA
    // 如需使用IDFA功能请添加此代码并在初始化方法的advertisingIdentifier参数中填写对应值
//    NSString *advertisingId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    
    // Required
    // init Push
    // notice: 2.1.5版本的SDK新增的注册方法，改成可上报IDFA，如果没有使用IDFA直接传nil
    // 如需继续使用pushConfig.plist文件声明appKey等配置内容，请依旧使用[JPUSHService setupWithOption:launchOptions]方式初始化。
    [JPUSHService setupWithOption:launchOptions appKey:@"179eb6b6a45f58c9675983ee" channel:@"App Store" apsForProduction:NO];
//    //  语音合成
//    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
//    AVSpeechUtterance *speechUtterance = [AVSpeechUtterance speechUtteranceWithString:@"圣域使者"];
//    //设置语言类别（不能被识别，返回值为nil）
//    speechUtterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
//    //设置语速快慢
//    speechUtterance.rate = 0.55;
//    //语音合成器会生成音频
//    [self.synthesizer speakUtterance:speechUtterance];
//    [self playMusic:@"jprefund" type:@"mp3"];
    // !!!: 只执行一次，默认开关全部打开
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:@"group.testpush"];
    [userDefault setBool:YES forKey:@"voice_value"];
    return YES;
}


- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    /// Required - 注册 DeviceToken
    [JPUSHService registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    //Optional
    NSLog(@"did Fail To Register For Remote Notifications With Error: %@", error);
}

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler {
    // Required
    NSDictionary * userInfo = notification.request.content.userInfo;
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    }
    completionHandler(UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
}

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    // Required
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    }
    completionHandler();  // 系统要求执行这个方法
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    // Required, iOS 7 Support
    [JPUSHService handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
    if ([UIDevice currentDevice].systemVersion.floatValue < 10.0) {
        [self playMusic:@"jprefund" type:@"mp3"];
    }
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    // Required,For systems with less than or equal to iOS6
    [JPUSHService handleRemoteNotification:userInfo];
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
