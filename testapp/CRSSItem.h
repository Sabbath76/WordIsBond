//
//  CRSSItem.h
//  testapp
//
//  Created by Jose Lopes on 31/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IconDownloader.h"
#import "TrackInfo.h"

typedef enum
{
    Text, Audio, Video
} PostType;

typedef enum
{
    Bandcamp, Soundcloud
} AudioHost;

@protocol PostRequestDelegate;

@interface CRSSItem : NSObject  < NSURLConnectionDelegate >

//This method kicks off a parse of a URL at a specified string
- (void)setup;

@property (nonatomic, retain) NSString *title;
//@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *blurb;
@property (nonatomic, retain) NSString *imageURLString;
@property (nonatomic, retain) NSString *mediaURLString;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *dateString;
@property (nonatomic, retain) NSString *postURL;
@property (nonatomic, retain) UIImage *appIcon;
@property (nonatomic, retain) UIImage *iconImage;
@property (nonatomic, retain) UIImage *blurredImage;
@property (nonatomic, readonly) PostType type;
@property (nonatomic, readonly) AudioHost audioHost;
@property (nonatomic, readonly) NSMutableArray *tracks;
@property (nonatomic, readwrite) int postID;
@property (nonatomic, readwrite) Boolean requiresDownload;

- (void) freeImages;
- (UIImage *) requestImage:(id<IconDownloaderDelegate>)delegate;
- (UIImage *) getBlurredImage;
- (UIImage *) requestIcon:(id<IconDownloaderDelegate>)delegate;
- (void) requestFullFeed:(id<PostRequestDelegate>)delegate;
- (void) addTrack:(TrackInfo *) track;
- (void) initWithDictionary:(NSDictionary*)post isFeature:(bool)isFeature;
- (void) initAsStub:(int)postId postTitle:(NSString*)postTitle isFeature:(bool)isFeature;
- (void) updateImage:(UIImage *)image icon:(UIImage *)imgIcon blur:(UIImage *)imgBlur;
- (Boolean) waitingOnTracks;

+ (void) setupDefaults;
+ (void) clearDefaults;

+ (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)coordSize;

@end


@protocol PostRequestDelegate

- (void)fullPostDidLoad:(CRSSItem *)post;

@end