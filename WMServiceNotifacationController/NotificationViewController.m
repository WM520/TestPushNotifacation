//
//  NotificationViewController.m
//  WMServiceNotifacationController
//
//  Created by wangmiao on 2017/12/5.
//  Copyright © 2017年 wangmiao. All rights reserved.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

@interface NotificationViewController () <UNNotificationContentExtension>

@property IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any required interface initialization here.
    self.imageView.layer.masksToBounds = YES;
}

- (void)didReceiveNotification:(UNNotification *)notification {
    NSDictionary * userInfo = notification.request.content.userInfo;
    NSLog(@"%@",userInfo);
    NSData * data = [userInfo objectForKey:@"image"];
    self.imageView.image = [UIImage imageNamed:@"wangmiao.jpg"];
    self.label.text = notification.request.content.body;
}

@end
