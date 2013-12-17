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

#import <Social/Social.h>

#import <Accounts/Accounts.h>

@interface DetailViewController ()
{
    __weak IBOutlet UIScrollView *m_header;
    __weak IBOutlet UIToolbar *m_toolbar;
    __weak IBOutlet UIView *m_titleRoot;
    __weak IBOutlet UILabel *m_title;
    __weak IBOutlet UILabel *m_date;
    PostHeaderController *m_currentPage;
    PostHeaderController *m_nextPage;
    UIBarButtonItem *m_btnFavourite;
    int m_itemPos;
    NSArray *m_sourceList;
    int m_toolbarOffset;
    bool m_loading;
    bool m_extendedNavBar;
}

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView:(bool)updateScroller;
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
        [self configureView:true];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)configureView :(bool) updateScroller
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
            m_loading = true;
        }
        
        NSMutableSet *favourites = [[UserData get] favourites];
        if ([favourites containsObject:self.detailItem])
        {
            m_btnFavourite.tintColor = [UIColor whiteColor];
        }
        else
        {
            m_btnFavourite.tintColor = [UIColor blackColor];
        }
        
        m_title.text = [self.detailItem title];
        m_date.text = [self.detailItem dateString];
        
        if (updateScroller)
        {
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
}


- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_banner_logo"]];

    m_currentPage = [[PostHeaderController alloc] initWithNibName:@"PostHeader" bundle:nil];
	m_nextPage = [[PostHeaderController alloc] initWithNibName:@"PostHeader" bundle:nil];
    
	[m_header addSubview:m_currentPage.view];
	[m_header addSubview:m_nextPage.view];
    
    [_webView setDelegate:self];
    
    [self configureView:true];
    
    self.webView.scrollView.delegate = self;
    float headerBottom = m_header.frame.origin.y + m_header.frame.size.height;
    [[self.webView scrollView] setContentInset:UIEdgeInsetsMake(headerBottom, 0, 0, 0)];
    
    if (m_itemPos > 0)
    {
        m_header.contentOffset = CGPointMake(m_header.frame.size.width*m_itemPos, 0);
    }
    
    m_toolbarOffset = 0;
    
    m_btnFavourite = self.btnFavourite;
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    [UIView animateWithDuration:0.5f animations:^{[_webView setAlpha:1.0f]; [m_currentPage.blurredImage setAlpha:0.0f];}];
    m_loading = false;
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
        m_btnFavourite.tintColor = [UIColor blackColor];
        [favourites removeObject:self.detailItem];
    }
    else
    {
        m_btnFavourite.tintColor = [UIColor whiteColor];
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

-(void) enableExtendedNavigationBar:(bool)enable
{
    if (enable != m_extendedNavBar)
    {
        m_extendedNavBar = enable;
        if (enable)
        {
//            UIToolbar *toolbar = [[UIToolbar alloc] init];
            UIBarButtonItem *commentButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"comment"] style:UIBarButtonItemStylePlain target:self action:@selector(onComment:)];
            UIBarButtonItem *fbButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"social_fb"] style:UIBarButtonItemStylePlain target:self action:@selector(onFacebook:)];
            UIBarButtonItem *twButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"social_tw"] style:UIBarButtonItemStylePlain target:self action:@selector(onTweet:)];
            UIBarButtonItem *favButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_fav"] style:UIBarButtonItemStylePlain target:self action:@selector(onFavourite:)];
            UIBarButtonItem *flexibleItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem *flexibleItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem *flexibleItem3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem *flexibleItem4 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
//            toolbar.items = @[flexibleItem1, commentButton, flexibleItem2, fbButton, flexibleItem3, twButton, flexibleItem4];
//            self.navigationItem.titleView = toolbar;
            [UIView animateWithDuration:0.4f animations:^{
            self.navigationItem.rightBarButtonItems = @[favButton, flexibleItem1, twButton, flexibleItem2, fbButton, flexibleItem3, commentButton, flexibleItem4 ];
            self.navigationItem.titleView = nil;
            self.navigationItem.title = @"";
                [m_toolbar setAlpha:0.0f];
            }];
            m_btnFavourite = favButton;
/*            [UIView animateWithDuration:0.4f animations:^{
            UIBarButtonItem *fbButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"social_fb"] style:UIBarButtonItemStylePlain target:self action:@selector(onFacebook:)];
            UIBarButtonItem *twButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"social_tw"] style:UIBarButtonItemStylePlain target:self action:@selector(onTweet:)];
            UIBarButtonItem *favButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_fav"] style:UIBarButtonItemStylePlain target:self action:@selector(onFavourite:)];
            self.navigationItem.rightBarButtonItems = @[favButton, fbButton,twButton];
                self.navigationItem.titleView = nil;}];*/
        }
        else
        {
            UIBarButtonItem *favButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_fav"] style:UIBarButtonItemStylePlain target:self action:@selector(onFavourite:)];
            [UIView animateWithDuration:0.4f animations:^{
            self.navigationItem.rightBarButtonItems = @[favButton];
            self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_banner_logo"]];
                [m_toolbar setAlpha:1.0f];
            }];
            m_btnFavourite = favButton;
        }
    }
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
    
        bool isPrev = (lowerNumber == m_itemPos);
        float pageFract = (fractionalPage - lowerNumber);
        float pageAlpha = isPrev ? (0.5f - pageFract) * 2.0f : (pageFract - 0.5f) * 2.0f;// fabsf(0.5f - pageFract) * 2.0f;
        pageAlpha = MAX(pageAlpha, 0.0f);
        float curAlpha = MIN(2.0f * pageFract, 1.0f);
        float nextAlpha = MIN(2.0f * (1.0f-pageFract), 1.0f);
        if (lowerNumber == m_nextPage.pageIndex)
        {
            nextAlpha = MIN(pageFract * 2.0f, 1.0f);
            curAlpha = MIN((1.0f-pageFract) * 2.0f, 1.0f);
        }
        if (!m_loading)
        {
            [self.webView setAlpha:pageAlpha];
            [m_currentPage.blurredImage setAlpha:curAlpha];
            [m_nextPage.blurredImage setAlpha:nextAlpha];
        }
        
        if (isPrev && (pageFract > 0.6f))
        {
            [UIView animateWithDuration:0.25f animations:^{[_webView setAlpha:0.0f];}];

            m_itemPos = upperNumber;
            _detailItem = m_sourceList[upperNumber];
            [self configureView:false];
        }
        else if (!isPrev && (pageFract < 0.4f))
        {
            [UIView animateWithDuration:0.25f animations:^{[_webView setAlpha:0.0f];}];
            m_itemPos = lowerNumber;
            _detailItem = m_sourceList[lowerNumber];
            [self configureView:false];
        }
    }
    else if (sender == _webView.scrollView)
    {
        float senderOffset  = sender.contentOffset.y;
        float headerPos = /*m_header.frame.origin.y + */m_header.frame.size.height;
        float delta = senderOffset+headerPos;
        float factor = 1.0f - (delta / (m_header.frame.size.height * 0.5f));
        if (factor <= 0.0f)
        {
            [m_header setAlpha:0.0f];
        }
        else
        {
            [m_header setAlpha:MIN(factor, 1.0f)];
        }
        
        
        CGRect titleFrame = [m_titleRoot frame];
        titleFrame.origin.y = MAX(-senderOffset, m_header.frame.origin.y);
        [m_titleRoot setFrame:titleFrame];
        CGRect tbFrame = [m_toolbar frame];
        tbFrame.origin.y = -senderOffset + titleFrame.size.height;
        [m_toolbar setFrame:tbFrame];
        
        [self enableExtendedNavigationBar:(senderOffset > 0)];
    }
}

- (IBAction)onComment:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"TODO"
                              message:@"Implement Comments."
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];

}

- (IBAction)onFacebook:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        CRSSItem *item = self.detailItem;
        
        [mySLComposerSheet setInitialText:@"Found a dope post on WIB"];
        
  //      [mySLComposerSheet addImage:item.appIcon];
        
        [mySLComposerSheet addURL:[NSURL URLWithString:item.postURL]];
        
        [self presentViewController:mySLComposerSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Cannot connect to Facebook"
                                  message:@"Please ensure that you are connected to the internet and have a valid Facebook account on this device."
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (IBAction)onTweet:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        CRSSItem *item = self.detailItem;
        
        [mySLComposerSheet setInitialText:@"Found a dope post on WIB"];
        
 //       [mySLComposerSheet addImage:item.appIcon];
        
        [mySLComposerSheet addURL:[NSURL URLWithString:item.postURL]];
        
        [self presentViewController:mySLComposerSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Cannot connect to Twitter"
                                  message:@"Please ensure that you are connected to the internet and have a valid Twitter account on this device."
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
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
