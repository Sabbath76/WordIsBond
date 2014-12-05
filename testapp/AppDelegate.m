//
//  AppDelegate.m
//  testapp
//
//  Created by Jose Lopes on 30/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "AppDelegate.h"
#import "UserData.h"
#import "GAI.h"
//#import "AFHTTPClient.h"

const NSString *notificationURL = @"http://www.thewordisbond.com/?json=register_notifications";

@implementation AppDelegate

- (void)customiseAppearance
{
//    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController; // this line is probably already there for you
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"WIBNavBar.jpg"] forBarMetrics:UIBarMetricsDefault]; //this adds the image
    UIImage *navBarImage = [[UIImage imageNamed:@"topbanner.jpg"]
                                resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 20, 0)];
  
    // Set the background image for *all* UINavigationBars
//    [[UINavigationBar appearance] setTitl setBackgroundImage:navBarImage
//                                       forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:navBarImage
                                       forBarMetrics:UIBarMetricsDefault];
    
//    [[UINavigationBar appearance] set setBarStyle:UIStatusBarStyleLightContent];
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"topbanner.jpg"]
//                                           forBarMetrics:UIBarMetricsDefault];
    
}

//- (UIStatusBarStyle) preferredStatusBarStyle
//{
//    return UIStatusBarStyleLightContent;
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    // TODO! Split view controller
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
//        id detailViewController =[splitViewController.viewControllers lastObject];
//        splitViewController.delegate = detailViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }

    //--- Init the URL cache to stop it eating too much memory
    int cacheSizeMemory = 4*1024*1024; // 4MB
    int cacheSizeDisk = 32*1024*1024; // 32MB
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"] ;
    [NSURLCache setSharedURLCache:sharedCache];

    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        // iOS 8 Notifications
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [application registerForRemoteNotifications];
    }
    else {
        // Let the device know we want to receive push notifications
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    

    [self customiseAppearance];
    
    application.applicationIconBadgeNumber = 0;
    
    NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification != nil)
    {
        NSNumber *postID = [remoteNotification objectForKey:@"postID"];
        if (postID)
        {
            //--- Start the application by switching to the selected post
            [[UserData get] setTargetPost:[postID intValue]];
        }
    }
    
    //--- Google Analytics
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 20;
//    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-11823155-6"];

/*    for (NSString* family in [UIFont familyNames])
    {
        NSLog(@"%@", family);
        
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
        {
            NSLog(@"  %@", name);
        }
    }
    
    [UIFont fontWithName:@"MyriadPro-Regular" size:20];
*/
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if (userInfo != nil)
    {
        NSNumber *postID = [userInfo objectForKey:@"postID"];
        if (postID)
        {
            //--- Start the application by switching to the selected post
            [[UserData get] setTargetPost:[postID intValue]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewRSSFeed" object:self];
        }
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSString *host = @"www.thewordisbond.com/wp-content/plugins/push-notifications-ios";
//    NSString *host = @"wordisbond.co/wp-content/plugins/push-notifications-ios";
    //http://www.thewordisbond.com/wp-content/plugins/push-notifications-ios/register_user_device.php

//    http://64.207.153.141/httpdocs/wp-content/plugins/push-notifications-ios/register_user_device.php	NSLog(@"My token is: %@", deviceToken);
    //http://64.207.153.141/wordisbond/wp-content/plugins/push-notifications-ios/register_user_device.php
    
	NSString *newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];

//#if !TARGET_IPHONE_SIMULATOR
    
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    NSUInteger rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    
    NSString *pushBadge = @"disabled";
    NSString *pushAlert = @"disabled";
    NSString *pushSound = @"disabled";
    
    if(rntypes == UIRemoteNotificationTypeBadge){
        pushBadge = @"enabled";
    }
    else if(rntypes == UIRemoteNotificationTypeAlert){
        pushAlert = @"enabled";
    }
    else if(rntypes == UIRemoteNotificationTypeSound){
        pushSound = @"enabled";
    }
    else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)){
        pushBadge = @"enabled";
        pushAlert = @"enabled";
    }
    else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)){
        pushBadge = @"enabled";
        pushSound = @"enabled";
    }
    else if(rntypes == ( UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)){
        pushAlert = @"enabled";
        pushSound = @"enabled";
    }
    else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)){
        pushBadge = @"enabled";
        pushAlert = @"enabled";
        pushSound = @"enabled";
    }
    
    UIDevice *dev = [UIDevice currentDevice];
    NSString *deviceUuid = dev.identifierForVendor.UUIDString;//dev.uniqueIdentifier is deprecated
    NSString *deviceName = dev.name;
    NSString *deviceModel = dev.model;
    NSString *deviceSystemVersion = dev.systemVersion;
    
//    NSString *deviceToken = [[[[devToken description]
//                               stringByReplacingOccurrencesOfString:@"<"withString:@""]
//                              stringByReplacingOccurrencesOfString:@">" withString:@""]
//                             stringByReplacingOccurrencesOfString: @" " withString: @""];

    NSString *urlString = [@"/register_user_device.php?"stringByAppendingString:@"task=register"];//when your app launch, it send request on this page to add devise in table

    urlString = [urlString stringByAppendingString:@"&appname="];
    urlString = [urlString stringByAppendingString:appName];
    urlString = [urlString stringByAppendingString:@"&appversion="];
    urlString = [urlString stringByAppendingString:appVersion];
    urlString = [urlString stringByAppendingString:@"&deviceuid="];
    urlString = [urlString stringByAppendingString:deviceUuid];
    urlString = [urlString stringByAppendingString:@"&devicetoken="];
    urlString = [urlString stringByAppendingString:newToken];
    urlString = [urlString stringByAppendingString:@"&devicename="];
    urlString = [urlString stringByAppendingString:deviceName];
    urlString = [urlString stringByAppendingString:@"&devicemodel="];
    urlString = [urlString stringByAppendingString:deviceModel];
    urlString = [urlString stringByAppendingString:@"&deviceversion="];
    urlString = [urlString stringByAppendingString:deviceSystemVersion];
    urlString = [urlString stringByAppendingString:@"&pushbadge="];
    urlString = [urlString stringByAppendingString:pushBadge];
    urlString = [urlString stringByAppendingString:@"&pushalert="];
    urlString = [urlString stringByAppendingString:pushAlert];
    urlString = [urlString stringByAppendingString:@"&pushsound="];
    urlString = [urlString stringByAppendingString:pushSound];
    
    NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:host path:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    NSError *error = nil;
    NSURLResponse *response;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *stringReply = (NSString *)[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
//    NSLog(@"reply from server: %@", stringReply);
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = [httpResponse statusCode];
//    NSLog(@"HTTP Response Headers %@", [httpResponse allHeaderFields]);
 //   NSLog(@"HTTP Status code: %d", statusCode);
    if(error != nil)
    {
        NSLog(@"Failed to connect for push notifications %@", [error localizedDescription]);
    }
    
    
//#endif
/*    NSDictionary *params = @{@"cmd":@"update",
                             @"user_id":@"TEST_ID",
                             @"token":newToken};
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:notificationURL]];
    [client
     postPath:@"/api.php"
     parameters:params
     success:nil failure:nil];
*/
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [[UserData get] save];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
