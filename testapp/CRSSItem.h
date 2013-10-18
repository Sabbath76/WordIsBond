//
//  CRSSItem.h
//  testapp
//
//  Created by Jose Lopes on 31/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IconDownloader.h"

typedef enum
{
    Text, Audio, Video
} PostType;

@protocol PostRequestDelegate;

@interface CRSSItem : NSObject  < NSURLConnectionDelegate >

//This method kicks off a parse of a URL at a specified string
- (void)setup;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *imageURLString;
@property (nonatomic, retain) NSString *mediaURLString;
@property (nonatomic, retain) UIImage *appIcon;
@property (nonatomic, readonly) PostType type;
@property (nonatomic, readwrite) int postID;
@property (nonatomic, readwrite) Boolean requiresDownload;

- (UIImage *) requestImage:(id<IconDownloaderDelegate>)delegate;
- (void) requestFullFeed:(id<PostRequestDelegate>)delegate;

@end


@protocol PostRequestDelegate

- (void)fullPostDidLoad:(CRSSItem *)post;

@end