//
//  IconDownloader.m
//  testapp
//
//  Created by Jose Lopes on 01/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//


#import "IconDownloader.h"
#import "CRSSItem.h"

#define kAppIconSize 48


@implementation IconDownloader
{
    NSMutableArray *delegateList;
};

static NSMutableDictionary *s_downloadingImages = NULL;
static NSMutableDictionary *s_downloadingImagesByID = NULL;

@synthesize appRecord;
@synthesize indexPathInTableView;
@synthesize isItem;
@synthesize postID;
//@synthesize delegate;
@synthesize activeDownload;
@synthesize imageConnection;

#pragma mark

//- (void)dealloc
//{
//    [CRSSItem release];
//    [indexPathInTableView release];
    
//    [activeDownload release];
    
//    [imageConnection cancel];
//    [imageConnection release];
    
//    [super dealloc];
//}

- (void)startDownload
{
    self.activeDownload = [NSMutableData data];
    // alloc+init and start an NSURLConnection; release on completion/failure
    NSURL *url = [NSURL URLWithString:[appRecord.imageURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//    [textField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:
                             [NSURLRequest requestWithURL:
                              url] delegate:self];
    self.imageConnection = conn;
//    [conn release];
}

- (void)cancelDownload
{
    [self.imageConnection cancel];
    self.imageConnection = nil;
    self.activeDownload = nil;
}


#pragma mark -
#pragma mark Download support (NSURLConnectionDelegate)

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.activeDownload appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // Clear the activeDownload property to allow later attempts
    self.activeDownload = nil;
    
    // Release the connection now that it's finished
    self.imageConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Set appIcon and clear temporary data/image
    UIImage *image = [[UIImage alloc] initWithData:self.activeDownload];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        [self.appRecord updateImage:image];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            //    self.appRecord.appIcon = image;
            self.activeDownload = nil;
            
            // Release the connection now that it's finished
            self.imageConnection = nil;
            
            for (id <IconDownloaderDelegate> delegateItem in delegateList)
            {
                [delegateItem appImageDidLoad:self];
            }
            
            [s_downloadingImagesByID removeObjectForKey:[NSNumber numberWithInt:self.postID]];
        });
    });

//    self.appRecord.appIcon = image;
/*    self.activeDownload = nil;
    
    // Release the connection now that it's finished
    self.imageConnection = nil;

    for (id <IconDownloaderDelegate> delegateItem in delegateList)
    {
        [delegateItem appImageDidLoad:self];
    }
    
    [s_downloadingImagesByID removeObjectForKey:[NSNumber numberWithInt:self.postID]];*/
}

+ (bool)download:(CRSSItem *)item indexPath:(NSIndexPath *)indexPathInTableView delegate:(id<IconDownloaderDelegate>)delegate isItem:(Boolean)isItem
{
    if ( s_downloadingImages == NULL)
    {
        s_downloadingImages = [NSMutableDictionary alloc];
    }
    
    IconDownloader *iconDownloader = [s_downloadingImages objectForKey:indexPathInTableView];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.appRecord = item;
        iconDownloader.indexPathInTableView = indexPathInTableView;
        iconDownloader->delegateList = [[NSMutableArray alloc] init];
        [iconDownloader->delegateList addObject:delegate];
        iconDownloader.isItem = isItem;
        [s_downloadingImages setObject:iconDownloader forKey:indexPathInTableView];
        [iconDownloader startDownload];
    }
    else
    {
        [iconDownloader->delegateList addObject:delegate];
        
    }

    return true;
}

+ (bool)download:(CRSSItem *)item delegate:(id<IconDownloaderDelegate>)delegate
{
    if ( s_downloadingImagesByID == NULL)
    {
        s_downloadingImagesByID = [[NSMutableDictionary alloc] init];
    }
    
    NSNumber *numPostID = [NSNumber numberWithInt:item.postID];
    IconDownloader *iconDownloader = [s_downloadingImagesByID objectForKey:numPostID];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.appRecord = item;
        iconDownloader->delegateList = [[NSMutableArray alloc] init];
        [iconDownloader->delegateList addObject:delegate];
        iconDownloader->postID = item.postID;
        [s_downloadingImagesByID setObject:iconDownloader forKey:numPostID];
        [iconDownloader startDownload];
    }
    else
    {
        [iconDownloader->delegateList addObject:delegate];
    }
    
    return true;
}

+ (void) removeDownload:(NSIndexPath *)indexPathInTableView
{
    [s_downloadingImages removeObjectForKey:indexPathInTableView];
}


@end