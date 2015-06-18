//
//  IconDownloader.m
//  testapp
//
//  Created by Jose Lopes on 01/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//


#import "IconDownloader.h"
#import "CRSSItem.h"
#import "UIImage+ImageEffects.h"

#import <ImageIO/ImageIO.h>

#define kAppIconSize 48

@implementation IconDownloader
{
    NSMutableArray *delegateList;
    NSString *pCachedFilename;
};

static NSMutableDictionary *s_downloadingImages = NULL;
static NSMutableDictionary *s_downloadingImagesByID = NULL;

@synthesize appRecord, appRecord2;
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
    NSString *theFileName = [NSString stringWithFormat:@"%@.png",[[appRecord.imageURLString lastPathComponent] stringByDeletingPathExtension]];
    self->pCachedFilename = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"tmp/%@",theFileName]];
    
//    NSFileManager *fileManager =[NSFileManager defaultManager];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
//        NSData *dataFromFile = nil;
        
        self->image = [UIImage imageWithContentsOfFile:self->pCachedFilename];
//        dataFromFile = [fileManager contentsAtPath:self->pCachedFilename];
        if(self->image)
        {
            [self distributeImage:self->pCachedFilename];
        }
        else
        {
            self.activeDownload = [NSMutableData data];
            // alloc+init and start an NSURLConnection; release on completion/failure
            NSURL *url = [NSURL URLWithString:[appRecord.imageURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            //    [textField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
            NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:
                                     [NSURLRequest requestWithURL:
                                      url] delegate:self];
            self.imageConnection = conn;
            CFRunLoopRun();
        }
    });

/*    self.activeDownload = [NSMutableData data];
    // alloc+init and start an NSURLConnection; release on completion/failure
    NSURL *url = [NSURL URLWithString:[appRecord.imageURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//    [textField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:
                             [NSURLRequest requestWithURL:
                              url] delegate:self];
    self.imageConnection = conn;*/
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
    
    CFRunLoopStop(CFRunLoopGetCurrent());
}

-(UIImage*)resizeImageToMaxSize:(CGFloat)max path:(NSString*)path
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], NULL);
    if (!imageSource)
        return nil;
    
    CFDictionaryRef options = (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                                                (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                                (id)[NSNumber numberWithFloat:max], (id)kCGImageSourceThumbnailMaxPixelSize,
                                                nil];
    CGImageRef imgRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options);
    
    UIImage* scaled = [UIImage imageWithCGImage:imgRef];
    
    CGImageRelease(imgRef);
    CFRelease(imageSource);
    
    return scaled;
}

-(void)distributeImage:(NSString*)imgPath
{
    // Set appIcon and clear temporary data/image
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        
//        UIImage *iconImage = [self resizeImageToMaxSize:60.0f path:imgPath];
        UIImage *iconImage = [CRSSItem resizeImage:self->image newSize:CGSizeMake(60.0f, 60.0f)];
        UIImage *blurredImage = [iconImage applyLightEffect];
        
        [self.appRecord updateImage:self->image icon:iconImage blur:blurredImage];
        [self.appRecord2 updateImage:self->image icon:iconImage blur:blurredImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{

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
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSFileManager *fileManager =[NSFileManager defaultManager];
    
    BOOL filecreationSuccess = [fileManager createFileAtPath:self->pCachedFilename contents:self.activeDownload attributes:nil];
    if(filecreationSuccess == NO){
        NSLog(@"Failed to create the cached file %@", self->pCachedFilename);
    }

    self->image = [UIImage imageWithContentsOfFile:self->pCachedFilename];
//    self->image = [[UIImage alloc] initWithData:self.activeDownload];
    
    // Set appIcon and clear temporary data/image
    [self distributeImage:self->pCachedFilename];

    CFRunLoopStop(CFRunLoopGetCurrent());

/*    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        [self.appRecord updateImage:self->image];
        [self.appRecord2 updateImage:self->image];
    
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
    });*/

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
        iconDownloader.appRecord2 = nil;
        iconDownloader.indexPathInTableView = indexPathInTableView;
        iconDownloader->delegateList = [[NSMutableArray alloc] init];
        [iconDownloader->delegateList addObject:delegate];
        iconDownloader.isItem = isItem;
        [s_downloadingImages setObject:iconDownloader forKey:indexPathInTableView];
        [iconDownloader startDownload];
    }
    else
    {
        if (iconDownloader.appRecord != item)
        {
            iconDownloader.appRecord2 = item;
        }
        if ([iconDownloader->delegateList containsObject:delegate] == false)
        {
            [iconDownloader->delegateList addObject:delegate];
        }
        
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
        if (iconDownloader.appRecord != item)
        {
            iconDownloader.appRecord2 = item;
        }
        [iconDownloader->delegateList addObject:delegate];
    }
    
    return true;
}

+ (void) removeDownload:(NSIndexPath *)indexPathInTableView
{
    [s_downloadingImages removeObjectForKey:indexPathInTableView];
}


@end