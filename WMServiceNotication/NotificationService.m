//
//  NotificationService.m
//  WMServiceNotication
//
//  Created by wangmiao on 2017/12/4.
//  Copyright © 2017年 wangmiao. All rights reserved.
//

#import "NotificationService.h"
#import <AVFoundation/AVFoundation.h>
#import <TestPushExtensionKit/TestPushExtensionKit.h>
#import "IBDataBase.h"
#import "IBNewsModel.h"
#import <YYModel/YYModel.h>

@interface NotificationService ()
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
    //  获取共享域的偏好设置
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:@"group.testpush"];
    
    //  解析推送自定义参数transInfo
    NSDictionary *transInfo = [self dictionaryWithUserInfo:self.bestAttemptContent.userInfo];
    IBNewsModel *model = [IBNewsModel yy_modelWithJSON:transInfo];
    //  数据本地存储
    [[IBDataBase sharedDataBase] addModel:model];
    BOOL canSound = [userDefault boolForKey:@"voice_value"];
    NSLog(@"%d", canSound);
    NSString *voiceString = nil;
    voiceString = [NSString stringWithFormat:@"退款%@元！", @"10"];
    //  语音合成
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *speechUtterance = [AVSpeechUtterance speechUtteranceWithString:voiceString];
    //设置语言类别（不能被识别，返回值为nil）
    speechUtterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    //设置语速快慢
    speechUtterance.rate = 0.55;
    //语音合成器会生成音频
    [self.synthesizer speakUtterance:speechUtterance];
    self.contentHandler(self.bestAttemptContent);
#warning 这里是添加一些事件的，比如点击进入查看详情，快捷回复等
//    NSMutableArray *actionMutableArr = [[NSMutableArray alloc] initWithCapacity:1];
//    UNNotificationAction * actionA  =[UNNotificationAction actionWithIdentifier:@"ActionA" title:@"不感兴趣" options:UNNotificationActionOptionAuthenticationRequired];
//
//    UNNotificationAction * actionB = [UNNotificationAction actionWithIdentifier:@"ActionB" title:@"不感兴趣" options:UNNotificationActionOptionDestructive];
//
//    UNNotificationAction * actionC = [UNNotificationAction actionWithIdentifier:@"ActionC" title:@"进去瞅瞅" options:UNNotificationActionOptionForeground];
//    UNTextInputNotificationAction * actionD = [UNTextInputNotificationAction actionWithIdentifier:@"ActionD" title:@"作出评论" options:UNNotificationActionOptionDestructive textInputButtonTitle:@"send" textInputPlaceholder:@"say some thing"];
//
//    [actionMutableArr addObjectsFromArray:@[actionA,actionB,actionC,actionD]];
//
//    if (actionMutableArr.count) {
//        UNNotificationCategory * notficationCategory = [UNNotificationCategory categoryWithIdentifier:@"categoryNoOperationAction" actions:actionMutableArr intentIdentifiers:@[@"ActionA",@"ActionB",@"ActionC",@"ActionD"] options:UNNotificationCategoryOptionCustomDismissAction];
//
//        [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithObject:notficationCategory]];
//
//    }
#pragma mark====================添加=categoryIdentifier============
//    self.bestAttemptContent.categoryIdentifier = @"myNotificationCategory";
//    self.contentHandler(self.bestAttemptContent);
//    NSDictionary *dict =  [self dictionaryWithUserInfo:self.bestAttemptContent.userInfo];
//    //    NSDictionary *notiDict = dict[@"aps"];
//    NSString *mediaUrl = [NSString stringWithFormat:@"%@",dict[@"media"][@"url"]];
//    NSLog(@"%@",mediaUrl);
//    if (!mediaUrl.length) {
//        self.contentHandler(self.bestAttemptContent);
//    }
//
//    [self loadAttachmentForUrlString:mediaUrl withType:dict[@"media"][@"type"] completionHandle:^(UNNotificationAttachment *attach) {
//
//        if (attach) {
//            self.bestAttemptContent.attachments = [NSArray arrayWithObject:attach];
//        }
//        self.contentHandler(self.bestAttemptContent);
//
//    }];
}

//处理视频，图片的等多媒体
- (void)loadAttachmentForUrlString:(NSString *)urlStr
                          withType:(NSString *)type
                  completionHandle:(void(^)(UNNotificationAttachment *attach))completionHandler{
    __block UNNotificationAttachment *attachment = nil;
    NSURL *attachmentURL = [NSURL URLWithString:urlStr];
    NSString *fileExt = [self fileExtensionForMediaType:type];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session downloadTaskWithURL:attachmentURL
                completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
                    if (error != nil) {
                        NSLog(@"%@", error.localizedDescription);
                    } else {
                        
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSURL *localURL = [NSURL fileURLWithPath:[temporaryFileLocation.path stringByAppendingString:fileExt]];
                        [fileManager moveItemAtURL:temporaryFileLocation toURL:localURL error:&error];
#pragma mark  自定义推送UI需要=========开始=========
                        
                        NSMutableDictionary * dict = [self.bestAttemptContent.userInfo mutableCopy];
                        [dict setObject:[NSData dataWithContentsOfURL:localURL] forKey:@"image"];
                        self.bestAttemptContent.userInfo = dict;
#pragma mark  自定义推送UI需要========结束=========
                        NSError *attachmentError = nil;
                        
                        attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:localURL options:nil error:&attachmentError];
                        
                        if (attachmentError) {
                            NSLog(@"%@", attachmentError.localizedDescription);
                        }
                    }
                    completionHandler(attachment);
                }] resume];
    
}

- (NSString *)fileExtensionForMediaType:(NSString *)type {
    NSString *ext = type;
    if ([type isEqualToString:@"image"]) {
        ext = @"jpg";
    }
    if ([type isEqualToString:@"video"]) {
        ext = @"mp4";
    }
    if ([type isEqualToString:@"audio"]) {
        ext = @"mp3";
    }
    return [@"." stringByAppendingString:ext];
}

//  解析推送消息数据
- (NSDictionary *)dictionaryWithUserInfo:(NSDictionary *)userInfo {
    
    if (userInfo.count <= 0) {
        return nil;
    }
    NSArray *keys = userInfo.allKeys;
    if ([keys containsObject:@"transInfo"]) {
        
        NSString *jsonString = userInfo[@"transInfo"];
        if ([jsonString containsString:@"\\"]) {
            jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        }
        
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
        
        if(err) {
            NSLog(@"json解析失败：%@",err);
            return nil;
        }
        return dic;
    } else {
        return nil;
    }
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}

@end
