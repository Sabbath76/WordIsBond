//
//  RSSFeed.h
//  testapp
//
//  Created by Jose Lopes on 21/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSSFeed : NSObject

@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) NSMutableArray *features;

- (void)handleLoadedApps:(NSArray *)loadedApps;
+ (RSSFeed *) getInstance;

@end
