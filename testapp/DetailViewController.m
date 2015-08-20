 //
//  DetailViewController.m
//  testapp
//
//  Created by Jose Lopes on 30/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "DetailViewController.h"
#import "UserData.h"
#import "FullPostController.h"
#import "RSSFeed.h"

#import <Social/Social.h>

#import <Accounts/Accounts.h>
#import "UIViewController+BackButtonHandler.h"

#import "SelectedItem.h"

#import "AppDelegate.h"

#import "GAI.h"
#import "GAIDictionaryBuilder.h"

#import "CoreDefines.h"


@interface DetailViewController ()
{
    __weak IBOutlet UIScrollView *m_header;
    FullPostController *m_currentPage;
    FullPostController *m_nextPage;
    __weak UIBarButtonItem *m_btnFavourite;
    __weak UIBarButtonItem *m_btnPlay;
    NSInteger m_itemPos;
    NSArray *m_sourceList;
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
        if (m_itemPos >= 0)
        {
            m_header.contentOffset = CGPointMake(m_header.frame.size.width*m_itemPos, 30);
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
        //--- Send information to Google Analytics
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"view post"     // Event category (required)
                                                              action:[self.detailItem title]  // Event action (required)
                                                             label:[[NSNumber numberWithInt:[self.detailItem postID]] stringValue]          // Event label
                                                               value:nil] build]];    // Event value

        NSInteger numItems = m_sourceList ? m_sourceList.count : 1;

        //--- Update UI based new post selection
        NSMutableArray *favourites = [[UserData get] favourites];
        if ([favourites containsObject:self.detailItem])
        {
            m_btnFavourite.tintColor = [UIColor wibColour];
        }
        else
        {
            m_btnFavourite.tintColor = [UIColor whiteColor];
        }
        
        if ((m_sourceList.count > 0) && ([m_sourceList[m_itemPos] tracks].count > 0))
        {
            m_btnPlay.tintColor = [UIColor whiteColor];
            [m_btnPlay setEnabled:true];
        }
        else
        {
            m_btnPlay.tintColor = [UIColor darkGrayColor];
            [m_btnPlay setEnabled:false];
        }
        
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
                m_header.contentSize = CGSizeMake(m_header.frame.size.width * numItems, 0);
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notifyNewDetailItem:)
                                                 name:@"SetDetailItem"
                                               object:nil];
    

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_banner_logo"]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        m_currentPage = [[FullPostController alloc] initWithNibName:@"FullPostiPad" bundle:nil];
        m_nextPage = [[FullPostController alloc] initWithNibName:@"FullPostiPad" bundle:nil];

        
        [self.splitViewController performSegueWithIdentifier: @"Loading" sender:self];

    }
    else
    {
        m_currentPage = [[FullPostController alloc] initWithNibName:@"FullPost" bundle:nil];
        m_nextPage = [[FullPostController alloc] initWithNibName:@"FullPost" bundle:nil];
    }
    
    m_btnFavourite = self.btnFavourite;

	[m_header addSubview:m_currentPage.view];
	[m_header addSubview:m_nextPage.view];
    
    [self enableExtendedNavigationBar:true];
    
    [self configureView:true];
    
    if (m_itemPos > 0)
    {
        m_header.contentOffset = CGPointMake(m_header.frame.size.width*m_itemPos, 30);
    }
    
    self.screenName = @"Post Details Screen";
//    self.automaticallyAdjustsScrollViewInsets = NO;
//    [m_header setContentInset:UIEdgeInsetsMake(64, 0, 64, 0)];


    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
    if(IS_OS_6_OR_LATER){
        
        [[NSNotificationCenter defaultCenter] addObserver:appDelegate selector:@selector(moviePlayerWillEnterFullscreenNotification:) name:@"UIMoviePlayerControllerDidEnterFullscreenNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:appDelegate selector:@selector(moviePlayerWillExitFullscreenNotification:) name:@"UIMoviePlayerControllerWillExitFullscreenNotification" object:nil];
        
    }
    if (IS_OS_8_OR_LATER) {
        
        [[NSNotificationCenter defaultCenter] addObserver:appDelegate selector:@selector(moviePlayerWillEnterFullscreenNotification:) name:UIWindowDidBecomeVisibleNotification object:self.view.window];
        [[NSNotificationCenter defaultCenter] addObserver:appDelegate selector:@selector(moviePlayerWillExitFullscreenNotification:) name:UIWindowDidBecomeHiddenNotification object:self.view.window];
        
    }
}

- (void) notifyNewDetailItem:(NSNotification *) notification
{
    RSSFeed *pFeed = [RSSFeed getInstance];
    SelectedItem *pDetailItem = (SelectedItem *)[notification object];
    if (pDetailItem->isFavourite)
    {
        NSArray *favouriteList = [[UserData get] favourites];
        [self setDetailItem:pDetailItem->item list:favouriteList];
    }
    else if (pDetailItem->isFeature)
    {
        [self setDetailItem:pDetailItem->item list:pFeed.features];
    }
    else
    {
        [self setDetailItem:pDetailItem->item list:pFeed.items];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
   
    if (m_header)
    {
        NSInteger numItems = m_sourceList ? m_sourceList.count : 1;
        m_header.contentSize = CGSizeMake(m_header.frame.size.width * numItems, 0);
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
    [barButtonItem setImage:[UIImage imageNamed:@"icon_opt"]];
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;

    if (m_currentPage)
    {
        [self applyNewIndex:m_itemPos pageController:m_currentPage];
    }
    if (m_nextPage)
    {
        [self applyNewIndex:m_itemPos+1 pageController:m_nextPage];
    }
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
    
    if (m_currentPage)
    {
        [self applyNewIndex:m_itemPos pageController:m_currentPage];
    }
    if (m_nextPage)
    {
        [self applyNewIndex:m_itemPos+1 pageController:m_nextPage];
    }

}

- (IBAction)onFavourite:(id)sender
{
    NSMutableArray *favourites = [[UserData get] favourites];
    if ([favourites containsObject:self.detailItem])
    {
        m_btnFavourite.tintColor = [UIColor whiteColor];
        [favourites removeObject:self.detailItem];
    }
    else
    {
        m_btnFavourite.tintColor = [UIColor wibColour];
        [favourites insertObject:self.detailItem atIndex:0];
    }
    [[UserData get] onChanged];
}


- (void)applyNewIndex:(NSInteger)newIndex pageController:(FullPostController *)pageController
{
	NSInteger pageCount = m_sourceList ? m_sourceList.count : 1;
	BOOL outOfBounds = newIndex >= pageCount || newIndex < 0;
    
	if (!outOfBounds)
	{
		CGRect pageFrame = pageController.view.frame;
		pageFrame.origin.y = 0;
		pageFrame.origin.x = m_header.frame.size.width * newIndex;
        pageFrame.size.height = m_header.frame.size.height;
        
		pageController.view.frame = pageFrame;
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
            //set back button color
            [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor,nil] forState:UIControlStateNormal];
            //set back button arrow color
            [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];

            UIBarButtonItem *playButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(onPlay:)];
//            UIBarButtonItem *commentButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_comments"] style:UIBarButtonItemStylePlain target:self action:@selector(onComment:)];
            UIBarButtonItem *fbButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"facebook_off"] style:UIBarButtonItemStylePlain target:self action:@selector(onFacebook:)];
            UIBarButtonItem *twButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"twitter_off"] style:UIBarButtonItemStylePlain target:self action:@selector(onTweet:)];
            UIBarButtonItem *favButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_favourite_off"] style:UIBarButtonItemStylePlain target:self action:@selector(onFavourite:)];
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
            {
//                [commentButton setTintColor:[UIColor whiteColor]];
                [fbButton setTintColor:[UIColor whiteColor]];
                [twButton setTintColor:[UIColor whiteColor]];
                [playButton setTintColor:[UIColor whiteColor]];
            }
            UIBarButtonItem *flexibleItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem *flexibleItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem *flexibleItem3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem *flexibleItem4 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

            [UIView animateWithDuration:0.4f animations:^{
            self.navigationItem.rightBarButtonItems = @[playButton, flexibleItem1, twButton, flexibleItem2, fbButton, flexibleItem3, favButton, flexibleItem4 ];
            self.navigationItem.titleView = nil;
            self.navigationItem.title = @"";
            }];
            m_btnFavourite = favButton;
            m_btnPlay = playButton;
        }
        else
        {
            UIBarButtonItem *favButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_fav"] style:UIBarButtonItemStylePlain target:self action:@selector(onFavourite:)];
            [UIView animateWithDuration:0.4f animations:^{
            self.navigationItem.rightBarButtonItems = @[favButton];
            self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_banner_logo"]];
            }];
            m_btnFavourite = favButton;
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (sender == m_header)
    {
        CGFloat pageWidth = m_header.frame.size.width;
        float fractionalPage = m_header.contentOffset.x / pageWidth;
            
        NSInteger lowerNumber = MAX(MIN(floor(fractionalPage), m_sourceList.count-2), 0);
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
        float pageAlpha = isPrev ? (0.5f - pageFract) * 4.0f : (pageFract - 0.5f) * 4.0f;// fabsf(0.5f - pageFract) * 2.0f;
        pageAlpha = MAX(pageAlpha, 0.0f);
        float curAlpha = MIN(2.0f * pageFract, 1.0f);
        float nextAlpha = MIN(2.0f * (1.0f-pageFract), 1.0f);
        if (lowerNumber == m_nextPage.pageIndex)
        {
            nextAlpha = MIN(pageFract * 2.0f, 1.0f);
            curAlpha = MIN((1.0f-pageFract) * 2.0f, 1.0f);
        }
        
        [m_currentPage setAlpha:curAlpha];
        [m_nextPage setAlpha:nextAlpha];
        
        if (isPrev && (pageFract > 0.6f))
        {
            m_itemPos = upperNumber;
            _detailItem = m_sourceList[upperNumber];
            [self configureView:false];
        }
        else if (!isPrev && (pageFract < 0.4f))
        {
            m_itemPos = lowerNumber;
            _detailItem = m_sourceList[lowerNumber];
            [self configureView:false];
        }
    }
}

- (IBAction)onPlay:(id)sender
{
    if ([m_sourceList[m_itemPos] tracks].count > 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayItem" object:m_sourceList[m_itemPos]];
    }
}

- (IBAction)onComment:(id)sender
{
    [m_currentPage goToComments];
}

- (IBAction)onFacebook:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        CRSSItem *item = self.detailItem;
        
        [mySLComposerSheet setInitialText:item.title];
        
        [mySLComposerSheet addImage:item.appIcon];
        
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
        
        [mySLComposerSheet setInitialText:item.title];
        
        [mySLComposerSheet addImage:item.appIcon];
        
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
		FullPostController *swapController = m_currentPage;
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
