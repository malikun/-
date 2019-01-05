//
//  NotificationService.m
//  MLKNotificationService
//
//  Created by TJF on 2018/12/3.
//  Copyright © 2018年 YCQH. All rights reserved.
//

#import "NotificationService.h"
#import "NotificationService.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "BPAudioManager.h"

@interface NotificationService ()<AVSpeechSynthesizerDelegate>

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@property (nonatomic, strong) AVSpeechSynthesisVoice *synthesisVoice;
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    NSDictionary *info = self.bestAttemptContent.userInfo;
    
    /*
     在这里进行了有两种处理方式,一种比较完美但是只使用与iOS 12.1以下版本
     另一种在后台播报时会有震动而且不可取消,并且在前台的时候需要在AppDelegate中进行处理
     两种方式皆可在后台以及进程被kill掉的情况下进行播报
     */
    if (@available(iOS 12.1, *)) {
        [self addOperation:[info[@"tts"] substringFromIndex:6]];
        
    }else{
        [self playVoiceWithContent:info[@"tts"]];
    }
}

#pragma mark -队列管理推送通知
- (void)addOperation:(NSString *)title {
    [[NSOperationQueue mainQueue] addOperation:[self customOperation:title]];
}


- (NSOperation *)customOperation:(NSString *)content {
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        
        [self pushNotificationWith:content];
    }];
    return operation;
}



- (void)playVoiceWithContent:(NSString *)content {
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:content];
    utterance.rate = 0.5;
    utterance.voice = self.synthesisVoice;
    [self.synthesizer speakUtterance:utterance];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    self.contentHandler(self.bestAttemptContent);
}

- (void)serviceExtensionTimeWillExpire {
    
    self.contentHandler(self.bestAttemptContent);
}

- (AVSpeechSynthesisVoice *)synthesisVoice {
    if (!_synthesisVoice) {
        _synthesisVoice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    }
    return _synthesisVoice;
}

- (AVSpeechSynthesizer *)synthesizer {
    if (!_synthesizer) {
        _synthesizer = [[AVSpeechSynthesizer alloc] init];
        _synthesizer.delegate = self;
    }
    return _synthesizer;
}



- (void)pushNotificationWith:(NSString *)moneyString{
    
    NSString *changeMoneyString = [BPAudioManager digitUppercase:moneyString];
    NSMutableArray *mp3Source = [NSMutableArray new];
    [mp3Source addObject:@"pre"];
    
    for (int i = 0; i < changeMoneyString.length; i++) {
        NSString * str = [changeMoneyString substringWithRange:NSMakeRange(i, 1)] ;
        
        if([str isEqualToString:@"零"]) {
            str = @"0" ;
        }
        else if([str isEqualToString:@"十"]) {
            str = @"ten" ;
        }
        else if([str isEqualToString:@"百"]) {
            str = @"hundred" ;
        }
        else if([str isEqualToString:@"千"]) {
            str = @"thousand" ;
        }
        else if([str isEqualToString:@"万"]) {
            str = @"ten_thousand" ;
        }
        else if([str isEqualToString:@"点"]) {
            str = @"dot" ;
        }
        else if([str isEqualToString:@"元"]) {
            str = @"yuan" ;
        }
        [mp3Source addObject:str];
    }
    __block int a = 0;
    __weak NotificationService *weakSelf = self;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL isFirstObject = YES;
        for (NSString *string in mp3Source) {
            CGFloat second = 0.45;
            if (isFirstObject) {
                isFirstObject = NO;
                second = 2;
            }
            __strong NotificationService *strongSelf = weakSelf;
            
            [self registerNotificationWithString:string completeHandler:^{
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_semaphore_signal(semaphore);
                    if (a == mp3Source.count) {
                        strongSelf.contentHandler(self.bestAttemptContent);
                    }
                });
            }];
            a++;
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
    });
}


- (void)registerNotificationWithString:(NSString *)string completeHandler:(dispatch_block_t)complete {
    
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        
        if (granted) {
            
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc]init];
            
            content.title = @"";
            content.subtitle = @"";
            content.body = @"";
            content.sound = [UNNotificationSound soundNamed:[NSString stringWithFormat:@"tts_%@.mp3",string]];
            
            content.categoryIdentifier = [NSString stringWithFormat:@"categoryIndentifier%@",string];
            
            UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.01 repeats:NO];
            
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"categoryIndentifier%@",string] content:content trigger:trigger];
            
            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                
                if (error == nil) {
                    
                    if (complete) {
                        complete();
                    }
                }
            }];
        }
    }];
}



@end

