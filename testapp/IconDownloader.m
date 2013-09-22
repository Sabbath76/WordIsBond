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
};

static NSMutableDictionary *s_downloadingImages;

@synthesize appRecord;
@synthesize indexPathInTableView;
@synthesize isItem;
@synthesize delegate;
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
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:
                             [NSURLRequest requestWithURL:
                              [NSURL URLWithString:appRecord.imageURLString]] delegate:self];
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
    
/*    if (image.size.width != kAppIconSize || image.size.height != kAppIconSize)
    {
        CGSize itemSize = CGSizeMake(kAppIconSize, kAppIconSize);
        UIGraphicsBeginImageContext(itemSize);
        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
        [image drawInRect:imageRect];
        self.appRecord.appIcon = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    else*/
    {
        self.appRecord.appIcon = image;
    }
    
    self.activeDownload = nil;
//    [image release];
    
    // Release the connection now that it's finished
    self.imageConnection = nil;
    
    // call our delegate and tell it that our icon is ready for display
    [delegate appImageDidLoad:self];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.appRecord forKey:@"item"];

    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"IconLoaded"
     object:self
     userInfo:userInfo];

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
        iconDownloader.delegate = delegate;
        iconDownloader.isItem = isItem;
        [s_downloadingImages setObject:iconDownloader forKey:indexPathInTableView];
        [iconDownloader startDownload];
    }

    return true;
}

+ (void) removeDownload:(NSIndexPath *)indexPathInTableView
{
    [s_downloadingImages removeObjectForKey:indexPathInTableView];
}


@end