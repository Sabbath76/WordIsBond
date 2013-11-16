 //
//  DetailViewController.m
//  testapp
//
//  Created by Jose Lopes on 30/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "DetailViewController.h"
#import "UserData.h"
#import "PostHeaderController.h"
#import "RSSFeed.h"

@interface DetailViewController ()
{
    __weak IBOutlet UIScrollView *m_header;
    PostHeaderController *m_currentPage;
    PostHeaderController *m_nextPage;
    int m_itemPos;
    NSArray *m_sourceList;
}

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem list:(NSArray *)sourceList
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        m_sourceList = sourceList;
        m_itemPos = -1;
        if (m_sourceList)
        {
            int itemCtr = 0;
            for (CRSSItem *item in m_sourceList)
            {
                if (item == self.detailItem)
                {
                    m_itemPos = itemCtr;
                    break;
                }
                itemCtr++;
            }
        }
        if (m_itemPos > 0)
        {
            m_header.contentOffset = CGPointMake(m_header.frame.size.width*m_itemPos, 0);
        }

        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem)
    {
        //self.title = [self.detailItem title];
        //self.detailDescriptionLabel.text = [self.detailItem description];
//        self.title = [self.detailItem title];
        
        
        if ([self.detailItem requiresDownload])
        {
            [self.detailItem requestFullFeed:self];
        }
        if (_webView)
        {
//            NSString *fullString = [NSString stringWithFormat:@"<div style='text-align:justify; font-size:45px;font-family:HelveticaNeue-CondensedBold;color:#0000;'>%@</div>", [self.detailItem description]];
//            [_webView loadHTMLString:fullString baseURL:nil];
            [_webView loadHTMLString:[self.detailItem blurb] baseURL:nil];
        }
        
        NSMutableSet *favourites = [[UserData get] favourites];
        if ([favourites containsObject:self.detailItem])
        {
            _btnFavourite.tintColor = [UIColor whiteColor];
        }
        else
        {
            _btnFavourite.tintColor = [UIColor blackColor];
        }
        
        if (m_currentPage)
        {
            [m_currentPage setSourceArray:m_sourceList];
            [self applyNewIndex:m_itemPos pageController:m_currentPage];
        }
        if (m_nextPage)
        {
            [m_nextPage setSourceArray:m_sourceList];
            [self applyNewIndex:m_itemPos+1 pageController:m_nextPage];
        }
        
        if (m_header)
        {
            int numItems = m_sourceList ? m_sourceList.count : 1;
            m_header.contentSize =
                CGSizeMake(
                   m_header.frame.size.width * numItems,
                   m_header.frame.size.height);
            //m_header.contentOffset = CGPointMake(0, 0);
        }

    }
}


- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Bond_logo132"]];

    m_currentPage = [[PostHeaderController alloc] initWithNibName:@"PostHeader" bundle:nil];
	m_nextPage = [[PostHeaderController alloc] initWithNibName:@"PostHeader" bundle:nil];
    
	[m_header addSubview:m_currentPage.view];
	[m_header addSubview:m_nextPage.view];
    
    [self configureView];
    
    self.webView.scrollView.delegate = self;
    float headerBottom = /*m_header.frame.origin.y +*/ m_header.frame.size.height;
    [[self.webView scrollView] setContentInset:UIEdgeInsetsMake(headerBottom, 0, 0, 0)];
    
    if (m_itemPos > 0)
    {
        m_header.contentOffset = CGPointMake(m_header.frame.size.width*m_itemPos, 0);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (void)fullPostDidLoad:(CRSSItem *)post
{
    if (post == self.detailItem)
    {
        if (_webView)
        {
            [_webView loadHTMLString:[self.detailItem blurb] baseURL:nil];
        }
        
        [post requestImage:self];
/*
        if (m_currentPage)
        {
            m_currentPage.pageIndex = m_currentPage.pageIndex;
        }
        
        if (m_nextPage)
        {
            m_nextPage.pageIndex = m_nextPage.pageIndex;
        }
 */
    }
}

- (IBAction)onFavourite:(id)sender
{
    NSMutableSet *favourites = [[UserData get] favourites];
    if ([favourites containsObject:self.detailItem])
    {
        _btnFavourite.tintColor = [UIColor blackColor];
        [favourites removeObject:self.detailItem];
    }
    else
    {
        _btnFavourite.tintColor = [UIColor whiteColor];
        [favourites addObject:self.detailItem];
    }
    [[UserData get] onChanged];
}


- (void)applyNewIndex:(NSInteger)newIndex pageController:(PostHeaderController *)pageController
{
	NSInteger pageCount = m_sourceList ? m_sourceList.count : 1;
	BOOL outOfBounds = newIndex >= pageCount || newIndex < 0;
    
	if (!outOfBounds)
	{
		CGRect pageFrame = pageController.view.frame;
		pageFrame.origin.y = 0;
		pageFrame.origin.x = m_header.frame.size.width * newIndex;
		pageController.view.frame = pageFrame;
        
	    CRSSItem *rssItem = m_sourceList ? m_sourceList[newIndex] : _detailItem;
        [rssItem requestImage:self];
    }
	else
	{
		CGRect pageFrame = pageController.view.frame;
		pageFrame.origin.y = m_header.frame.size.height;
		pageController.view.frame = pageFrame;
	}
    
	pageController.pageIndex = newIndex;
}


// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
    if (iconDownloader != nil)
    {
        CRSSItem *featureNext = m_sourceList && (m_nextPage.pageIndex < m_sourceList.count) ? m_sourceList[m_nextPage.pageIndex] : _detailItem;
        CRSSItem *featureCurrent = m_sourceList && (m_nextPage.pageIndex < m_sourceList.count) ? m_sourceList[m_currentPage.pageIndex] : _detailItem;
        UIImage *newImage = iconDownloader.appRecord.appIcon;
        if (featureNext.postID == iconDownloader.postID)
        {
            m_nextPage.imageView.image = newImage;
            m_nextPage.pageIndex = m_nextPage.pageIndex;
        }
        if (featureCurrent.postID == iconDownloader.postID)
        {
            m_currentPage.imageView.image = newImage;
            m_currentPage.pageIndex = m_currentPage.pageIndex;
        }
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (sender == m_header)
    {
    CGFloat pageWidth = m_header.frame.size.width;
    float fractionalPage = m_header.contentOffset.x / pageWidth;
	
	NSInteger lowerNumber = floor(fractionalPage);
	NSInteger upperNumber = lowerNumber + 1;
	
	if (lowerNumber == m_currentPage.pageIndex)
	{
		if (upperNumber != m_nextPage.pageIndex)
		{
			[self applyNewIndex:upperNumber pageController:m_nextPage];
		}
	}
	else if (upperNumber == m_currentPage.pageIndex)
	{
		if (lowerNumber != m_nextPage.pageIndex)
		{
			[self applyNewIndex:lowerNumber pageController:m_nextPage];
		}
	}
	else
	{
		if (lowerNumber == m_nextPage.pageIndex)
		{
			[self applyNewIndex:upperNumber pageController:m_currentPage];
		}
		else if (upperNumber == m_nextPage.pageIndex)
		{
			[self applyNewIndex:lowerNumber pageController:m_currentPage];
		}
		else
		{
			[self applyNewIndex:lowerNumber pageController:m_currentPage];
			[self applyNewIndex:upperNumber pageController:m_nextPage];
		}
	}
	
	[m_currentPage updateTextViews:NO];
	[m_nextPage updateTextViews:NO];
    
        float pageFract = (fractionalPage - lowerNumber);
        float pageAlpha = fabsf(0.5f - pageFract) * 2.0f;
        [self.webView setAlpha:pageAlpha];
        
        if ((lowerNumber == m_itemPos) && (pageFract > 0.6f))
        {
            m_itemPos = upperNumber;
            _detailItem = m_sourceList[upperNumber];
            [self configureView];
        }
        else if (pageFract < 0.4f)
        {
            m_itemPos = lowerNumber;
            _detailItem = m_sourceList[lowerNumber];
            [self configureView];
        }
    }
    else if (sender == _webView.scrollView)
    {
        float headerPos = m_header.frame.origin.y + m_header.frame.size.height;
        float delta = sender.contentOffset.y+headerPos;
        float factor = 1.0f - (delta / (m_header.frame.size.height * 0.5f));
        if (factor <= 0.0f)
        {
            [m_header setAlpha:0.0f];
        }
        else
        {
            [m_header setAlpha:MIN(factor, 1.0f)];
        }
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)sender
{
    if (sender == m_header)
    {
    CGFloat pageWidth = m_header.frame.size.width;
    float fractionalPage = m_header.contentOffset.x / pageWidth;
	NSInteger nearestNumber = lround(fractionalPage);
    
	if (m_currentPage.pageIndex != nearestNumber)
	{
		PostHeaderController *swapController = m_currentPage;
		m_currentPage = m_nextPage;
		m_nextPage = swapController;
	}
    
	[m_currentPage updateTextViews:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{
    if (sender == m_header)
    {
	[self scrollViewDidEndScrollingAnimation:sender];
    }
}


@end
