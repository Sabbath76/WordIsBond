//
//  CoreDefines.m
//  WordIsBond
//
//  Created by Jose Lopes on 14/04/2015.
//  Copyright (c) 2015 Tom Berry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDefines.h"


#define WEB_HOST @"www.thewordisbond.com/"
#define WEB_URL @"http://www.thewordisbond.com/"
//#define WEB_HOST @"wordisbond.co/"
//#define WEB_URL @"http://wordisbond.co/"
//http://www.thewordisbond.com/?json=appqueries.get_recent_features&count=5


NSString * const BASE_WEB_URL               = WEB_URL;

NSString * const NOTIFICATION_URL = (WEB_HOST @"wp-content/plugins/push-notifications-ios");

NSString * const SERVER_POSTS_URL = (WEB_URL @"?json=appqueries.get_recent_posts&count=20");
NSString * const SERVER_FEATURES_URL = (WEB_URL @"?json=appqueries.get_recent_features&count=5");
NSString * const SERVER_SEARCH_POSTS_URL = (WEB_URL @"?json=appqueries.get_search_results&count=20&search=");
NSString * const SERVER_SEARCH_FEATURES_URL = (WEB_URL @"?json=appqueries.get_search_feature_results&count=5&search=");

NSString * const SERVER_REQUEST_FULL_POST_URL = (WEB_URL @"?json=get_post&id=");

NSString * const BAND_CAMP_KEY         = @"godsthannlitanpalafreyregna";
NSString * const BAND_CAMP_ALBUM_QUERY = @"http://api.bandcamp.com/api/album/2/info?key=godsthannlitanpalafreyregna&album_id=";
NSString * const BAND_CAMP_TRACK_URL   = @"http://popplers5.bandcamp.com/download/track?enc=mp3-128&id=%@&stream=1";
