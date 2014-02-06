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

#import "MediaTrackController.h"
#import <QuartzCore/QuartzCore.h>
#import "RSSFeed.h"
#import "CRSSItem.h"
#import "IconDownloader.h"
#import "SelectedItem.h"


@implementation MediaTrackController
{
    NSArray *m_sourceArray;
    __weak IBOutlet UIButton *m_trackImage;
}

@synthesize pageIndex;

- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
 /*   RSSFeed *feed = [RSSFeed getInstance];

	if (pageIndex >= 0 && pageIndex < feed.features.count)
	{
        TrackInfo *rssItem = feed.features[pageIndex];
        if (rssItem.postID == iconDownloader.postID)
        {
            _imageView.image = rssItem.appIcon;
            _blurredImage.image = rssItem.blurredImage;
        }
    }*/
}

- (void)setPageIndex:(NSInteger)newPageIndex
{
	pageIndex = newPageIndex;
	
	if (pageIndex >= 0 && pageIndex < m_sourceArray.count)
	{
        TrackInfo *trackInfo = m_sourceArray[pageIndex];

        [m_trackImage setImage:trackInfo->pItem.appIcon forState:UIControlStateNormal];
        [m_trackImage setImage:trackInfo->pItem.appIcon forState:UIControlStateSelected];

//        _imageView.image = trackInfo->pItem.appIcon;
//        _blurredImage.image = rssItem.blurredImage;
        label.text = trackInfo->title;
        artist.text = trackInfo->artist;
 //       dateView.text = rssItem.dateString;
 //       author.text = rssItem.author;
	}
}

- (void)updateTextViews:(BOOL)force
{
}

- (void)setSourceArray:(NSArray*)array
{
    m_sourceArray = array;
}

- (IBAction)onPostClick:(id)sender
{
    if (m_sourceArray)
    {
        SelectedItem *item = [SelectedItem alloc];
        item->isFavourite = false;
        TrackInfo *track = m_sourceArray[pageIndex];
        item->item = track->pItem;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ViewPost" object:item];
    }
}

@end

