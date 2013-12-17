//
//  FeatureCell.m
//  testapp
//
//  Created by Jose Lopes on 21/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "FeatureCell.h"
#import "CRSSItem.h"
#import "IconDownloader.h"

#import "DetailViewController.h"
#import "FeatureController.h"
#import <QuartzCore/QuartzCore.h>

@implementation FeatureCell
{
    __weak IBOutlet UIImageView *m_imgHighlight;
    NSArray *m_thumbnails;
}

@synthesize scrollView, rssFeed, detailViewController;
@synthesize imageView1, imageView2, imageView3, imageView4;

- (void)awakeFromNib
{
    leftMostFeature = 0;
    
    scrollView.delegate = self;
    
    currentPage = [[FeatureController alloc] initWithNibName:@"featureCell" bundle:nil];
	nextPage = [[FeatureController alloc] initWithNibName:@"featureCell" bundle:nil];

	[scrollView addSubview:currentPage.view];
	[scrollView addSubview:nextPage.view];
    
    rssFeed = [RSSFeed getInstance];
    [self layoutIfNeeded];
    [self updateFeed];

    UIImage *stretchableImage = (id)[UIImage imageNamed:@"cornerfull"];

    CALayer *_maskingLayer1 = [CALayer layer];
    CALayer *_maskingLayer2 = [CALayer layer];
    CALayer *_maskingLayer3 = [CALayer layer];
    CALayer *_maskingLayer4 = [CALayer layer];
    
    _maskingLayer1.frame = imageView1.bounds;
    _maskingLayer1.contents = (id)stretchableImage.CGImage;
    _maskingLayer1.contentsScale = [UIScreen mainScreen].scale; //<-needed for the retina display, otherwise our image will not be scaled properly
    _maskingLayer1.contentsCenter = CGRectMake(15.0/stretchableImage.size.width,15.0/stretchableImage.size.height,5.0/stretchableImage.size.width,5.0f/stretchableImage.size.height);

    _maskingLayer2.frame = imageView2.bounds;
    _maskingLayer2.contents = (id)stretchableImage.CGImage;
    _maskingLayer2.contentsScale = [UIScreen mainScreen].scale; //<-needed for the retina display, otherwise our image will not be scaled properly
    _maskingLayer2.contentsCenter = CGRectMake(15.0/stretchableImage.size.width,15.0/stretchableImage.size.height,5.0/stretchableImage.size.width,5.0f/stretchableImage.size.height);
    _maskingLayer3.frame = imageView3.bounds;
    _maskingLayer3.contents = (id)stretchableImage.CGImage;
    _maskingLayer3.contentsScale = [UIScreen mainScreen].scale; //<-needed for the retina display, otherwise our image will not be scaled properly
    _maskingLayer3.contentsCenter = CGRectMake(15.0/stretchableImage.size.width,15.0/stretchableImage.size.height,5.0/stretchableImage.size.width,5.0f/stretchableImage.size.height);
    _maskingLayer4.frame = imageView4.bounds;
    _maskingLayer4.contents = (id)stretchableImage.CGImage;
    _maskingLayer4.contentsScale = [UIScreen mainScreen].scale; //<-needed for the retina display, otherwise our image will not be scaled properly
    _maskingLayer4.contentsCenter = CGRectMake(15.0/stretchableImage.size.width,15.0/stretchableImage.size.height,5.0/stretchableImage.size.width,5.0f/stretchableImage.size.height);

    [imageView1.layer setMask:_maskingLayer1];
    [imageView2.layer setMask:_maskingLayer2];
    [imageView3.layer setMask:_maskingLayer3];
    [imageView4.layer setMask:_maskingLayer4];
    
    m_thumbnails = [[NSArray alloc] initWithObjects:imageView1, imageView2, imageView3, imageView4, nil];
}

- (void) viewDidAppear
{
    [self updateFeed];
 
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onFeature:(id)sender
{
    int index = leftMostFeature+[sender tag];
    [scrollView scrollRectToVisible:CGRectMake(scrollView.frame.size.width*index, 0, scrollView.frame.size.width , scrollView.frame.size.height) animated:YES];
    [self updateHighlight:index];
}

- (void)updateHighlight:(int)index
{
    int thumb = index-leftMostFeature;
    if ((thumb >= 0) && (thumb < m_thumbnails.count))
    {
    UIButton *button = (UIButton*) m_thumbnails[thumb];
    [UIView animateWithDuration:0.4f animations:^
        {
        [m_imgHighlight setFrame:[button frame]];
         }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetailFeature"])
    {
        if (self.scrollView)
        {
            int curFeature = round(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
            
            CRSSItem *object = rssFeed.features[curFeature];
            [[segue destinationViewController] setDetailItem:object list:rssFeed.features];
        }
    }
}

- (void)updateFeed
{
    scrollView.contentSize =
    CGSizeMake(
               scrollView.frame.size.width * rssFeed.features.count,
               scrollView.frame.size.height);
	scrollView.contentOffset = CGPointMake(0, 0);
    
    leftMostFeature = -1;
    
	[self applyNewIndex:0 pageController:currentPage];
	[self applyNewIndex:1 pageController:nextPage];
}


- (void)applyNewIndex:(NSInteger)newIndex pageController:(FeatureController *)pageController
{
	NSInteger pageCount = rssFeed.features.count;
	BOOL outOfBounds = newIndex >= pageCount || newIndex < 0;
    
	if (!outOfBounds)
	{
		CGRect pageFrame = pageController.view.frame;
		pageFrame.origin.y = 0;
		pageFrame.origin.x = scrollView.frame.size.width * newIndex;
		pageController.view.frame = pageFrame;

	    CRSSItem *rssItem = rssFeed.features[newIndex];
        [rssItem requestImage:self];
    }
	else
	{
		CGRect pageFrame = pageController.view.frame;
		pageFrame.origin.y = scrollView.frame.size.height;
		pageController.view.frame = pageFrame;
	}
    
	pageController.pageIndex = newIndex;

    int maxFeatures = rssFeed.features.count;
    int newleftmost = MAX(MIN(leftMostFeature, newIndex-1), newIndex-2);
    newleftmost = MAX(MIN(maxFeatures - 4, newleftmost), 0);
    if (newleftmost != leftMostFeature)
    {
        leftMostFeature = newleftmost;
        if ((self.imageView1 != NULL) && (leftMostFeature < pageCount))
        {
            CRSSItem *rssItem1 = rssFeed.features[leftMostFeature];
            [imageView1 setImage:[rssItem1 requestImage:self] forState:UIControlStateNormal];
        }
        if ((self.imageView2 != NULL) && (leftMostFeature+1 < pageCount))
        {
            CRSSItem *rssItem2 = rssFeed.features[leftMostFeature+1];
            [imageView2 setImage:[rssItem2 requestImage:self] forState:UIControlStateNormal];
        }
        if ((self.imageView3 != NULL) && (leftMostFeature+2 < pageCount))
        {
            CRSSItem *rssItem3 = rssFeed.features[leftMostFeature+2];
            [imageView3 setImage:[rssItem3 requestImage:self] forState:UIControlStateNormal];
        }
        if ((self.imageView4 != NULL) && (leftMostFeature+3 < pageCount))
        {
            CRSSItem *rssItem4 = rssFeed.features[leftMostFeature+3];
            [imageView4 setImage:[rssItem4 requestImage:self] forState:UIControlStateNormal];
        }

       [self updateHighlight:currentPage.pageIndex];
    }

}


// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
    if (iconDownloader != nil)
    {
        CRSSItem *featureNext = rssFeed.features[nextPage.pageIndex];
        CRSSItem *featureCurrent = rssFeed.features[currentPage.pageIndex];
        UIImage *newImage = iconDownloader.appRecord.appIcon;
        if (featureNext.postID == iconDownloader.postID)
        {
            nextPage.imageView.image = newImage;
        }
        if (featureCurrent.postID == iconDownloader.postID)
        {
            currentPage.imageView.image = newImage;
        }
        
        if (((CRSSItem *)rssFeed.features[leftMostFeature]).postID == iconDownloader.postID)
        {
            [imageView1 setImage:newImage forState:UIControlStateNormal];
        }
        else if (((CRSSItem *)rssFeed.features[leftMostFeature+1]).postID == iconDownloader.postID)
        {
            [imageView2 setImage:newImage forState:UIControlStateNormal];
        }
        else if (((CRSSItem *)rssFeed.features[leftMostFeature+2]).postID == iconDownloader.postID)
        {
            [imageView3 setImage:newImage forState:UIControlStateNormal];
        }
        else if (((CRSSItem *)rssFeed.features[leftMostFeature+3]).postID == iconDownloader.postID)
        {
            [imageView4 setImage:newImage forState:UIControlStateNormal];
        }
        
//        [IconDownloader removeDownload:iconDownloader.indexPathInTableView];
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
	
	NSInteger lowerNumber = floor(fractionalPage);
	NSInteger upperNumber = lowerNumber + 1;
	
	if (lowerNumber == currentPage.pageIndex)
	{
		if (upperNumber != nextPage.pageIndex)
		{
			[self applyNewIndex:upperNumber pageController:nextPage];
		}
	}
	else if (upperNumber == currentPage.pageIndex)
	{
		if (lowerNumber != nextPage.pageIndex)
		{
			[self applyNewIndex:lowerNumber pageController:nextPage];
		}
	}
	else
	{
		if (lowerNumber == nextPage.pageIndex)
		{
			[self applyNewIndex:upperNumber pageController:currentPage];
		}
		else if (upperNumber == nextPage.pageIndex)
		{
			[self applyNewIndex:lowerNumber pageController:currentPage];
		}
		else
		{
			[self applyNewIndex:lowerNumber pageController:currentPage];
			[self applyNewIndex:upperNumber pageController:nextPage];
		}
	}
	
	[currentPage updateTextViews:NO];
	[nextPage updateTextViews:NO];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)newScrollView
{
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
	NSInteger nearestNumber = lround(fractionalPage);
    
	if (currentPage.pageIndex != nearestNumber)
	{
		FeatureController *swapController = currentPage;
		currentPage = nextPage;
		nextPage = swapController;
	}
    
    [self updateHighlight:currentPage.pageIndex];
    
	[currentPage updateTextViews:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)newScrollView
{
	[self scrollViewDidEndScrollingAnimation:newScrollView];
}

@end
