//
//  RSSFeed.m
//  testapp
//
//  Created by Jose Lopes on 21/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//


#import "CRSSItem.h"
#import "RSSFeed.h"

@implementation RSSFeed
{
}

@synthesize items, features;

- (void)handleLoadedApps:(NSArray *)loadedApps
{
    //    [self.appRecords addObjectsFromArray:loadedApps];
    
    items = [[NSMutableArray alloc] init];
    features = [[NSMutableArray alloc] init];
    for (CRSSItem *item in loadedApps)
    {
        [items insertObject:item atIndex:0];
        [features insertObject:item atIndex:0];
    }
}

@end
