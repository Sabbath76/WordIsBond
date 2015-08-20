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
#import "CoreDefines.h"
#import "RSSFeed.h"
#import "CRSSItem.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface AppDelegate ()
{
    NSDate *lastUpdateTime;
    bool isInBackground;
    bool allowRotation;
    bool hasNewData;
}

@end

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
    
///    [[UINavigationBar appearance] setBarTintColor:[UIColor wibTintColour]];
//    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
//    [[UINavigationBar appearance] set setBarStyle:UIStatusBarStyleLightContent];
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"topbanner.jpg"]
//                                           forBarMetrics:UIBarMetricsDefault];
    
}

//- (UIStatusBarStyle) preferredStatusBarStyle
//{
//    return UIStatusBarStyleLightContent;
//}
void myExceptionHandler(NSException *exception)
{
    NSArray *stack = [exception callStackReturnAddresses];
//    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//    [tracker sendException:YES // Boolean indicates non-fatal exception.
//           withDescription:@"Exception: %@", stack];
    NSLog(@"Stack trace: %@", stack);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    isInBackground = false;
//    NSSetUncaughtExceptionHandler(&myExceptionHandler);
    
//    // TODO! Split view controller
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
//        id detailViewController =[splitViewController.viewControllers lastObject];
//        splitViewController.delegate = detailViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
        [splitViewController setMinimumPrimaryColumnWidth:320];
    }
    
    [Fabric with:@[CrashlyticsKit]];
    
    //--- Init the URL cache to stop it eating too much memory
    int cacheSizeMemory = 4*1024*1024; // 4MB
    int cacheSizeDisk = 32*1024*1024; // 32MB
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"] ;
    [NSURLCache setSharedURLCache:sharedCache];

    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        // iOS 8 Notifications
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
//        [application registerForRemoteNotifications];
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
    [GAI sharedInstance].trackUncaughtExceptions = NO;
    [GAI sharedInstance].dispatchInterval = 20;
//    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-11823155-6"];
    
    allowRotation = false;
    isInBackground = false;
    hasNewData = false;
    lastUpdateTime = [NSDate date];
    
    return YES;
}

- (void) moviePlayerWillEnterFullscreenNotification:(NSNotification*)notification {
    allowRotation = YES; }

- (void) moviePlayerWillExitFullscreenNotification:(NSNotification*)notification {
    allowRotation = NO;
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}


- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    if (notificationSettings.types != UIUserNotificationTypeNone)
    {
        [application registerForRemoteNotifications];
    }
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

//            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewRSSFeed" object:self];
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    UIApplicationState state = [application applicationState];
    // user tapped notification while app was in background
    if ((state == UIApplicationStateInactive) || (state == UIApplicationStateBackground))
    {
        hasNewData = true;
        
        // go to screen relevant to Notification content
        NSNumber *postID = [userInfo objectForKey:@"postID"];
        if (postID)
        {
            //--- Start the application by switching to the selected post
            [[UserData get] setTargetPost:[postID intValue]];
        }
    }
    else
    {
        // App is in UIApplicationStateActive (running in foreground)
        // perhaps show an UIAlertView
    }
    
    [application setApplicationIconBadgeNumber:[[[userInfo objectForKey:@"aps"] objectForKey:@"badge"] intValue]];
    
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSString * const host = NOTIFICATION_URL;
    
	NSString *newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    NSString *pushBadge = @"disabled";
    NSString *pushAlert = @"disabled";
    NSString *pushSound = @"disabled";

    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)])
    {
        UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        NSUInteger rntypes = [notificationSettings types];
        
        if (rntypes & UIUserNotificationTypeBadge)
        {
            pushBadge = @"enabled";
        }
        if (rntypes & UIUserNotificationTypeAlert)
        {
            pushAlert = @"enabled";
        }
        if (rntypes & UIUserNotificationTypeSound)
        {
            pushSound = @"enabled";
        }
    }
    else
    {
        NSUInteger rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        
        if(rntypes & UIRemoteNotificationTypeBadge){
            pushBadge = @"enabled";
        }
        if(rntypes & UIRemoteNotificationTypeAlert){
            pushAlert = @"enabled";
        }
        if(rntypes & UIRemoteNotificationTypeSound){
            pushSound = @"enabled";
        }
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
//    NSString *urlString = [@"/test.php?"stringByAppendingString:@"task=register"];//when your app launch, it send request on this page to add devise in table

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
    NSLog(@"reply from server: %@", stringReply);
//    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
//    NSInteger statusCode = [httpResponse statusCode];
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
    isInBackground = true;

    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [[UserData get] save];
    
    RSSFeed *feed = [RSSFeed getInstance];
    for (CRSSItem *item in feed.items)
    {
        [item freeImages];
    }
    for (CRSSItem *feature in feed.features)
    {
        [feature freeImages];
    }
    [CRSSItem clearDefaults];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSDate *curTime = [NSDate date];
    
    NSTimeInterval timeSinceUpdate = [curTime timeIntervalSinceDate:lastUpdateTime];

    if (isInBackground)
    {
        isInBackground = false;
        
        if (hasNewData || (timeSinceUpdate > (60.0f * 60.0f * 6.0f)))
        {
            // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
            RSSFeed *feed = [RSSFeed getInstance];
            [feed LoadPage:[feed GetPage]];

            application.applicationIconBadgeNumber = 0;
            
            hasNewData = false;
            lastUpdateTime = curTime;

            [[NSNotificationCenter defaultCenter] postNotificationName:@"OnBeginRefresh" object:feed];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    [[UserData get] save];
}

-(BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if  ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) || allowRotation ){
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
