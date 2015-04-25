//
//  IconDownloader.h
//  testapp
//
//  Created by Jose Lopes on 01/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

@class CRSSItem;
@class MasterViewController;

@protocol IconDownloaderDelegate;

@interface IconDownloader : NSObject
{
    CRSSItem *appRecord;
    CRSSItem *appRecord2;
    NSIndexPath *indexPathInTableView;
    id <IconDownloaderDelegate> delegate;
    Boolean isItem;
//    int postID;
    UIImage *image;
    
    NSMutableData *activeDownload;
    NSURLConnection *imageConnection;
}

@property (nonatomic, retain) CRSSItem *appRecord;
@property (nonatomic, retain) CRSSItem *appRecord2;
@property (nonatomic, retain) NSIndexPath *indexPathInTableView;
@property (nonatomic, readwrite) Boolean isItem;
@property (nonatomic, readonly) int postID;

@property (nonatomic, retain) NSMutableData *activeDownload;
@property (nonatomic, retain) NSURLConnection *imageConnection;

- (void)startDownload;
- (void)cancelDownload;
+ (bool)download:(CRSSItem *)item indexPath:(NSIndexPath *)indexPathInTableView delegate:(id<IconDownloaderDelegate>)delegate isItem:(Boolean)isItem;
+ (bool)download:(CRSSItem *)item delegate:(id<IconDownloaderDelegate>)delegate;
+ (void) removeDownload:(NSIndexPath *)indexPathInTableView;

@end

@protocol IconDownloaderDelegate

- (void)appImageDidLoad:(IconDownloader *)iconDownloader;

@end