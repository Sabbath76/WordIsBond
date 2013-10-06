//
//  PageViewController.m
//  PagingScrollView
//
//  Created by Matt Gallagher on 24/01/09.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "FeatureController.h"
#import <QuartzCore/QuartzCore.h>
#import "RSSFeed.h"
#import "CRSSItem.h"


const CGFloat TEXT_VIEW_PADDING = 50.0;

@implementation FeatureController

@synthesize pageIndex;

- (void)setPageIndex:(NSInteger)newPageIndex
{
	pageIndex = newPageIndex;
    RSSFeed *feed = [RSSFeed getInstance];
	
	if (pageIndex >= 0 && pageIndex < feed.features.count)
	{
        CRSSItem *rssItem = feed.features[pageIndex];
        
//        UIImage *mask = [UIImage imageNamed:@"banner_mask"];
//        CGImageRef imgRef = [rssItem.appIcon CGImage];
//        CGImageRef maskRef = [mask CGImage];
//        CGImageRef actualMask = CGImageMaskCreate(CGImageGetWidth(maskRef),
//                                                  CGImageGetHeight(maskRef),
//                                                  CGImageGetBitsPerComponent(maskRef),
//                                                  CGImageGetBitsPerPixel(maskRef),
//                                                  CGImageGetBytesPerRow(maskRef),
//                                                  CGImageGetDataProvider(maskRef), NULL, false);
//        CGImageRef masked = CGImageCreateWithMask(imgRef, actualMask);
        
//        imageView.image = [UIImage imageWithCGImage:masked];
        
        imageView.image = rssItem.appIcon;
        label.text = rssItem.title;
/*		NSDictionary *pageData =
			[[DataSource sharedDataSource] dataForPage:pageIndex];
		label.text = [pageData objectForKey:@"pageName"];
		textView.text = [pageData objectForKey:@"pageText"];
		
		CGRect absoluteRect = [self.view.window
			convertRect:textView.bounds
			fromView:textView];
		if (!self.view.window ||
			!CGRectIntersectsRect(
				CGRectInset(absoluteRect, TEXT_VIEW_PADDING, TEXT_VIEW_PADDING),
				[self.view.window bounds]))
		{
			textViewNeedsUpdate = YES;
		}
*/	}
}

- (void)updateTextViews:(BOOL)force
{
	if (force ||
		(textViewNeedsUpdate &&
		self.view.window &&
		CGRectIntersectsRect(
			[self.view.window
				convertRect:CGRectInset(textView.bounds, TEXT_VIEW_PADDING, TEXT_VIEW_PADDING)
				fromView:textView],
			[self.view.window bounds])))
	{
		for (UIView *childView in textView.subviews)
		{
			[childView setNeedsDisplay];
		}
		textViewNeedsUpdate = NO;
	}
}

@end

