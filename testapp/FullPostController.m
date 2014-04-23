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

#import "FullPostController.h"
#import <QuartzCore/QuartzCore.h>
#import "RSSFeed.h"
#import "CRSSItem.h"
#import "IconDownloader.h"


@implementation FullPostController
{
    __weak IBOutlet UIImageView *m_image;
    __weak IBOutlet UIImageView *m_blurredImage;
    __weak IBOutlet UILabel *m_title;
    __weak IBOutlet UILabel *m_date;
    __weak IBOutlet UILabel *m_author;
    __weak IBOutlet UIWebView *m_webView;
    __weak IBOutlet UIToolbar *m_toolbarRegion;
    __weak IBOutlet UIView *m_headerText;
    NSArray *m_sourceArray;
    float m_offset;
}

@synthesize pageIndex;

- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
	if (pageIndex >= 0 && pageIndex < m_sourceArray.count)
	{
        CRSSItem *rssItem = m_sourceArray[pageIndex];

        if (rssItem.postID == iconDownloader.postID)
        {
            m_image.image = rssItem.appIcon;
            m_blurredImage.image = rssItem.blurredImage;
        }
    }
}

- (void)setPageIndex:(NSInteger)newPageIndex
{
	pageIndex = newPageIndex;
	
	if (pageIndex >= 0 && pageIndex < m_sourceArray.count)
	{
        CRSSItem *rssItem = m_sourceArray[pageIndex];

        if ([rssItem requiresDownload])
        {
            [rssItem requestFullFeed:self];
        }

        m_webView.scrollView.delegate = self;

        m_image.image = [rssItem requestImage:self];
        m_blurredImage.image = [rssItem getBlurredImage];
        m_title.text = rssItem.title;
        m_date.text = rssItem.dateString;
        if (rssItem.author != nil)
        {
            m_author.text = [@"By " stringByAppendingString:rssItem.author];
        }
        [m_webView loadHTMLString:[rssItem blurb] baseURL:[NSURL URLWithString:[rssItem postURL]]];
        
        m_offset = 80.0f;
        
        float headerBottom = 220.0f;
        [[m_webView scrollView] setContentInset:UIEdgeInsetsMake(headerBottom, 0, 0, 0)];
    }
}

- (void)fullPostDidLoad:(CRSSItem *)post
{
    CRSSItem *rssItem = m_sourceArray[pageIndex];
    if (post.postID == rssItem.postID)
    {
        [self setPageIndex:pageIndex];
    }
}


- (void)updateTextViews:(BOOL)force
{
}

- (void)setSourceArray:(NSArray*)array
{
    m_sourceArray = array;
}

- (void)setAlpha:(float)alpha
{
    [m_blurredImage setAlpha:alpha];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (sender == m_webView.scrollView)
    {
        float defaultImageHeight = m_offset;
        float senderOffset  = sender.contentOffset.y+defaultImageHeight;
        float headerPos = 130;///*m_header.frame.origin.y + */m_image.frame.size.height;
        float delta = senderOffset+headerPos;
        float factor = (delta / defaultImageHeight);
        if (factor <= 0.0f)
        {
            [m_blurredImage setAlpha:0.0f];
        }
        else
        {
            [m_blurredImage setAlpha:MIN(factor, 1.0f)];
        }
        
//        senderOffset += m_scrollOffset;
        
        CGRect titleFrame = [m_headerText frame];
        titleFrame.origin.y = MAX(-senderOffset, m_image.frame.origin.y);
        [m_headerText setFrame:titleFrame];
        [m_toolbarRegion setFrame:titleFrame];
/*        CGRect tbFrame = [m_toolbar frame];
        tbFrame.origin.y = -senderOffset + titleFrame.size.height;
        [m_toolbar setFrame:tbFrame];*/

        CGRect imageFrame = m_image.frame;
        imageFrame.size.height = titleFrame.origin.y - imageFrame.origin.y;
        [m_image setFrame:imageFrame];
        [m_blurredImage setFrame:imageFrame];
    }
}

@end

