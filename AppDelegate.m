//
//  AppDelegate.m
//  语音播报
//
//  Created by TJF on 2019/1/5.
//  Copyright © 2019年 马立坤. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFAudio.h>

@interface AppDelegate ()
@property (nonatomic,strong) AVSpeechSynthesizer *synthConfig;
@property (nonatomic,strong) AVSpeechSynthesisVoice *voiceConfig;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler{
   
    
    if (@available(iOS 12.1, *)) {
        [self readNoticeContent:userInfo[@"tts"]];
    }
}

- (void)readNoticeContent:(NSString *)content{
    [self addOperation:content];
}

#pragma mark -队列管理推送通知
- (void)addOperation:(NSString *)title {
    [[NSOperationQueue mainQueue] addOperation:[self customOperation:title]];
}


- (NSOperation *)customOperation:(NSString *)content {
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        AVSpeechUtterance *utterance = nil;
        @autoreleasepool {
            utterance = [AVSpeechUtterance speechUtteranceWithString:content];
            utterance.rate = 0.5;
        }
        utterance.voice = self.voiceConfig;
        [self.synthConfig speakUtterance:utterance];
    }];
    return operation;
}

- (AVSpeechSynthesizer *)synthConfig {
    if (_synthConfig == nil) {
        _synthConfig = [[AVSpeechSynthesizer alloc] init];
    }
    return _synthConfig;
}

- (AVSpeechSynthesisVoice *)voiceConfig {
    if (_voiceConfig == nil) {
        _voiceConfig = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    }
    return _voiceConfig;
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
