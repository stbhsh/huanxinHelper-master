//
//  XAspect-IMchatHuanxin.m
//  IM_huanxin
//
//  Created by  icwmac3 on 2016/12/28.
//  Copyright © 2016年 IM_huanxin. All rights reserved.
//

#import "AppDelegate.h"
#import "XAspect.h"
#import "AppDelegate+EaseMob.h"
#import "EaseUI.h"
#import "JPUSHService.h"
#import "ChatDemoHelper.h"


#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif
#define HuanxinAppKey       @"AppID"

#define AtAspect IMhuanxindelegate

#define AtAspectOfClass AppDelegate

@classPatchField(AppDelegate)

@synthesizeNucleusPatch(Default, -, BOOL, application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions);
@synthesizeNucleusPatch(Default, -, void, application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken);
@synthesizeNucleusPatch(Default, -, void, application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error);
@synthesizeNucleusPatch(Default, -, void, userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler);
@synthesizeNucleusPatch(Default, -, void, application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification);

@synthesizeNucleusPatch(Default, -, void, userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler);

@synthesizeNucleusPatch(Default, -, void, applicationDidEnterBackground:(UIApplication *)application);

@synthesizeNucleusPatch(Default, -, void, applicationWillEnterForeground:(UIApplication *)application);


AspectPatch(-, BOOL, application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions)
{
    
    if (NSClassFromString(@"UNUserNotificationCenter")) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    }
    
    
    NSString *apnsCertName = nil;
#if DEBUG
    apnsCertName = @"you_dev";// 开发证书
#else
    apnsCertName = @"you_dis";// 生产证书
#endif
    
    
    
    [self easemobApplication:application
didFinishLaunchingWithOptions:launchOptions
                      appkey:HuanxinAppKey
                apnsCertName:apnsCertName
                 otherConfig:@{kSDKConfigEnableConsoleLogger:[NSNumber numberWithBool:YES]}];
    return XAMessageForward(application:application didFinishLaunchingWithOptions:launchOptions);
}




AspectPatch( -, void, applicationDidEnterBackground:(UIApplication *)application) {
    [[EMClient sharedClient] applicationDidEnterBackground:application];
    return  XAMessageForward(applicationDidEnterBackground:application);

}

AspectPatch( -, void, applicationWillEnterForeground:(UIApplication *)application) {
    [[EMClient sharedClient] applicationWillEnterForeground:application];
    return XAMessageForward(applicationWillEnterForeground:application);
    
}


AspectPatch( -, void, application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification) {
    
    //处理页面跳转问题
    
    return XAMessageForward(application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification);
}

// 本地通知
AspectPatch( -, void, userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler) {
  
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    if (userInfo[@"_j_msgid"]) {
     //处理页面跳转问题
    
    }
    return XAMessageForward(userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:(void (^)())completionHandler);
}

//点击  ios10前台通知调用
AspectPatch( -, void,  userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler) {
    
    NSDictionary *userInfo = notification.request.content.userInfo;
    if (userInfo[@"g"]) {
        [self didReceiveRemoteNotification:userInfo];
        //处理页面跳转问题

        
    }
    return XAMessageForward(userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler);
}



- (void)easemobApplication:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
appkey:(NSString *)appkey
apnsCertName:(NSString *)apnsCertName
otherConfig:(NSDictionary *)otherConfig
{
    //注册登录状态监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginStateChange:)
                                                 name:KNOTIFICATION_LOGINCHANGE
                                               object:nil];
    
    [[EaseSDKHelper shareHelper] hyphenateApplication:application
                        didFinishLaunchingWithOptions:launchOptions
                                               appkey:appkey
                                         apnsCertName:apnsCertName
                                          otherConfig:@{kSDKConfigEnableConsoleLogger:[NSNumber numberWithBool:YES]}];
    
    
    BOOL isAutoLogin = [EMClient sharedClient].isAutoLogin;
    if (isAutoLogin){
        [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@YES];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@NO];
    }
}

- (void)easemobApplication:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[EaseSDKHelper shareHelper] hyphenateApplication:application didReceiveRemoteNotification:userInfo];
    
    
    
}

#pragma mark - App Delegate

AspectPatch(-, void, application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken)
{
    NSString *myToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    myToken = [myToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        
        [[EMClient sharedClient] bindDeviceToken:deviceToken];
    });
    // 注册极光推送
    [JPUSHService registerDeviceToken:deviceToken];
    
    
    return XAMessageForward(application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken);
}

/** 远程通知注册失败委托 */
AspectPatch(-, void, application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error){
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"apns.failToRegisterApns", Fail to register apns)
                                                    message:error.description
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                          otherButtonTitles:nil];
    [alert show];
    return XAMessageForward(application:application didFailToRegisterForRemoteNotificationsWithError:error);
}




#pragma mark - login changed

- (void)loginStateChange:(NSNotification *)notification
{
    BOOL loginSuccess = [notification.object boolValue];
    
    if (loginSuccess) {//登陆成功加载主窗口控制器
        [[ChatDemoHelper shareHelper] asyncGroupFromServer];
        [[ChatDemoHelper shareHelper] asyncConversationFromDB];
        [[ChatDemoHelper shareHelper] asyncPushOptions];
        
        
        
    }
    else{//登陆失败加载登陆页面控制器
        
        
        
    }
    
}

#pragma mark - EMPushManagerDelegateDevice

// 打印收到的apns信息
-(void)didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSError *parseError = nil;
    NSData  *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo
                                                        options:NSJSONWritingPrettyPrinted error:&parseError];
    NSString *str =  [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"apns.content", @"Apns content")
                                                    message:str
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                          otherButtonTitles:nil];
    NSLog(@"打印收到的apns信息 打印收到的apns信息 %@",userInfo);
    alert.delegate =self;
    
    alert.tag = 100;
    
    [alert show];
    
}

@end

