//
//  RSSFeed.h
//  testapp
//
//  Created by Jose Lopes on 21/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RSSFeed : NSObject < NSURLConnectionDelegate >

@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) NSMutableArray *features;
@property (nonatomic, readonly) int numNewFront;
@property (nonatomic, readonly) int numNewBack;
@property (nonatomic, readonly) Boolean reset;

- (void)handleLoadedApps:(NSArray *)loadedApps;
+ (RSSFeed *) getInstance;
- (void) Filter:(NSString *)filter showAudio:(bool)showAudio showVideo:(bool)showVideo showText:(bool)showText;
- (void) FilterJSON:(NSString *)filter showAudio:(bool)showAudio showVideo:(bool)showVideo showText:(bool)showText;
- (int) GetPage;
- (int) GetNumPages;
- (void) LoadPage:(int) pageNum;
- (void) LoadFeed;
- (void) clearSearch;

@end
