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

#import "PostHeaderController.h"
#import <QuartzCore/QuartzCore.h>
#import "RSSFeed.h"
#import "CRSSItem.h"
#import "IconDownloader.h"


@implementation PostHeaderController
{
    NSArray *m_sourceArray;
}

@synthesize pageIndex;

- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
    RSSFeed *feed = [RSSFeed getInstance];

	if (pageIndex >= 0 && pageIndex < feed.features.count)
	{
        CRSSItem *rssItem = feed.features[pageIndex];
        if (rssItem.postID == iconDownloader.postID)
        {
            _imageView.image = rssItem.appIcon;
        }
    }
}

- (void)setPageIndex:(NSInteger)newPageIndex
{
	pageIndex = newPageIndex;
	
	if (pageIndex >= 0 && pageIndex < m_sourceArray.count)
	{
        CRSSItem *rssItem = m_sourceArray[pageIndex];

        _imageView.image = rssItem.appIcon;
        label.text = rssItem.title;
        dateView.text = rssItem.dateString;
        author.text = rssItem.author;
	}
}

- (void)updateTextViews:(BOOL)force
{
}

- (void)setSourceArray:(NSArray*)array
{
    m_sourceArray = array;
}


@end
