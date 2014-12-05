//
//  MasterViewController.m
//  testapp
//
//  Created by Jose Lopes on 30/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

#import "ViewControllerRoot.h"

#import "RSSParser.h"
#import "RSSFeed.h"

#import "FeatureCell.h"
#import "PostCell.h"
#import "UIToolbarDragger.h"

#import "FeatureViewController.h"
#import "UserData.h"

#import "SelectedItem.h"

#import <MediaPlayer/MediaPlayer.h>

#import <Social/Social.h>

#import <Accounts/Accounts.h>

typedef enum
{
    LoadNewer,
    Features,
    Posts,
    LoadOlder,
    Total_Sections
} ESection;

const int SectionSize[Total_Sections] =
{
    30, 210, 80, 60
};

const float PAN_CLOSED_X = 0;
const float PAN_OPEN_X = -250;
const float FAST_ANIMATION_DURATION = 0.5f;

const int ExpandedSectionSize = 120;

@interface MasterViewController ()
{
    __weak IBOutlet UIButton *m_btnFavourite;
    
    RSSFeed *_feed;

    RSSParser *m_parser;
    
    FeatureCell *m_featureCell;
    
    FeatureViewController *m_featuresController;
    ViewControllerRoot *m_rootViewController;
    
    UIImageView *m_searchOverlay;
    UIImageView *m_searchSpinner;
    
    SelectedItem *m_forcedDetailItem;
    
    UIView *m_quickMenu;
    
    NSInteger m_currentQuickMenuItem;
    
    NSIndexPath *m_expandedIndexPath;
    
    NSIndexPath *m_lastPannedIndexPath;
    float m_lastPannedX;

    float m_slideInitialPos;

    bool m_searchShouldBeginEditing;
    bool m_isLoadingMoreData;
    bool m_isInitialising;
}


- (void)startIconDownload:(CRSSItem *)appRecord forIndexPath:(NSIndexPath *)indexPath;    // thequeue to run our "ParseOperation"

@end

@implementation MasterViewController

@synthesize imageDownloadsInProgress, toolbar;

- (void) setMenuOpen:(bool)state
{
    [m_rootViewController setMenuOpen:state];
/*    UIView *rootView = self.navigationController.view.superview.superview;
    CGRect destination = rootView.frame;
    
    if (state)
    {
        destination.origin.x = 270;
        _btnMenu.tintColor = [UIColor blackColor];
        
        [rootView setUserInteractionEnabled:false];
    }
    else
    {
        destination.origin.x = 0;
        _btnMenu.tintColor = [UIColor whiteColor];
        
        [rootView setUserInteractionEnabled:true];
    }
    
    [UIView beginAnimations:@"Bringing up menu" context:nil];
    rootView.frame = destination;
    [UIView commitAnimations];*/
}

- (void) wobbleMenu
{
    UIView *rootView = self.navigationController.view.superview.superview;
    CGRect initialFrame = rootView.frame;
    CGRect destination = initialFrame;
    destination.origin.x = 20;

    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^{
                         rootView.frame = destination;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.15
                                               delay:0.0
                                             options:0
                                          animations:^{
                                              rootView.frame = initialFrame;
                                          }
                                          completion:^(BOOL finished) {}];
                     }];
    
    [UIView beginAnimations:@"Wobble menu" context:nil];
    rootView.frame = destination;
    [UIView commitAnimations];

}

- (void) selectDetail:(CRSSItem *)item
{
    [self setMenuOpen:false];
}

- (IBAction)onQuickMenu:(id)sender
{
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        if (indexPath.section == Posts)
        {
            PostCell *postCell = (PostCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            if (postCell.expandButton == sender)
            {
                [self doExpandPost:indexPath];
                break;
            }
        }
    }

}

- (void) setRootController:(UIViewController*) controller
{
    m_rootViewController = (ViewControllerRoot*)controller;;
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)onMenu:(id)sender
{
    CGRect destination = self.navigationController.view.superview.superview.frame;
    
    bool menuOpen = (destination.origin.x == 0);
    
    [self setMenuOpen:menuOpen];
}

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    
    [CRSSItem setupDefaults];
    
    m_parser = [RSSParser alloc];
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
    
    _feed = [RSSFeed getInstance];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    m_isLoadingMoreData = false;
    m_isInitialising = true;
    
    m_currentQuickMenuItem = -1;

    [self createTopBanner];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WIB_BG"]];
    self.tableView.backgroundView = imageView;
    
    [super awakeFromNib];
    
    self.navigationController.view.layer.shadowOffset = CGSizeMake(-15, 10);
    self.navigationController.view.layer.shadowRadius = 5;
    self.navigationController.view.layer.shadowOpacity = 0.5;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNewRSSFeed:)
                                                 name:@"NewRSSFeed"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(failedNewRSSFeed:)
                                                 name:@"FailedFeed"
                                               object:nil];
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveViewPost:)
                                                 name:@"ViewPost"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateMenuState:)
                                                 name:@"UpdateMenuState"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTargetPost:)
                                                 name:@"UpdateTargetPost"
                                               object:nil];
    
    
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
//    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    [refresh setTintColor:[UIColor whiteColor]];
    UIFont * font = [UIFont fontWithName:@"Helvetica-Light" size:10.0];
    NSDictionary *attributes = @{NSFontAttributeName:font, NSForegroundColorAttributeName : [UIColor whiteColor]};
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Get latest posts" attributes:attributes];

    [refresh addTarget:self action:@selector(loadNewer) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;
    self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
    });
    
//    UISwipeGestureRecognizer *swipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePost:)];
//    [swipeRecognizerLeft setDirection:(UISwipeGestureRecognizerDirectionLeft)];
//    [self.tableView addGestureRecognizer:swipeRecognizerLeft];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [panRecognizer setDelegate:self];
    [self.tableView addGestureRecognizer:panRecognizer];

    UISwipeGestureRecognizer *swipeRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(expandPost:)];
    [swipeRecognizerRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.tableView addGestureRecognizer:swipeRecognizerRight];
    
//    [self.tableView registerClass:[PostCell class] forCellReuseIdentifier:@"ItemCell"];


/*    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 2.0; //seconds
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];*/
    
    m_quickMenu = [[[NSBundle mainBundle] loadNibNamed:@"PostQuickMenu" owner:self options:nil] objectAtIndex:0];

    m_searchOverlay = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WIB_BG_blur"]];
//    CGRect vframe = self.view.frame;
    CGRect frame = self.tableView.frame;
    m_searchOverlay.frame = frame;
    m_searchSpinner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_loading"]];
    m_searchSpinner.frame = frame;
    m_searchSpinner.contentMode = UIViewContentModeCenter;
//    m_searchOverlay = [[UIView alloc]  initWithFrame:self. view.frame];
//    m_searchOverlay.backgroundColor=[UIColor blackColor];
    m_searchOverlay.alpha = 0;
    m_searchSpinner.alpha = 0;
    [m_searchOverlay addSubview:m_searchSpinner];
    
    //--- Load the first few items straight away
    [self loadImagesForOnscreenRows];
}

- (void) createTopBanner
{
    UIImageView *pImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_banner_logo"]];
    self.navigationItem.titleView = pImageView;
    
    UINavigationController *navController = self.navigationController;
    [navController.navigationBar setTintColor:[UIColor blackColor]];
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(onTapTitle:)];
    singleFingerTap.numberOfTapsRequired = 1;
    [pImageView addGestureRecognizer:singleFingerTap];
    [pImageView setUserInteractionEnabled:true];
}

- (void) loadNewer
{
    int newPage = MAX([_feed GetPage]-1, 0);
    [_feed LoadPage:newPage];
}

- (void)onTapTitle:(UITapGestureRecognizer *)recognizer
{
    //--- Pan list view up to the top
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseMediaPlayer"  object:self];
}

- (void)startIconDownload:(CRSSItem *)appRecord forIndexPath:(NSIndexPath *)indexPath
{
    [IconDownloader download:appRecord delegate:self];
}

// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
    if (iconDownloader != nil)
    {
        NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visibleRows)
        {
            if (indexPath.section == Posts)
            {
            if (((CRSSItem *)_feed.items[indexPath.row]).postID == iconDownloader.postID)
            {
                PostCell *cell = (PostCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//                UIImageView *imgView = (UIImageView *)[cell viewWithTag:2];
//                UIImageView *imgViewMini = (UIImageView *)[cell viewWithTag:4];
                cell.blurredImage.image = iconDownloader.appRecord.blurredImage;
                cell.miniImage.image = iconDownloader.appRecord.iconImage;

                break;
            }
            }
        }
//        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        
        // Display the newly loaded image
//        UIImageView *imgView = (UIImageView *)[cell viewWithTag:2];
//        imgView.image = iconDownloader.appRecord.appIcon;
//        cell.imageView.image = iconDownloader.appRecord.appIcon;
//    }
    
    // Remove the IconDownloader from the in progress list.
    // This will result in it being deallocated.
//    [imageDownloadsInProgress removeObjectForKey:iconDownloader.indexPathInTableView];
    }
}

// -------------------------------------------------------------------------------
//  handleLoadedApps:notif
// -------------------------------------------------------------------------------
- (void)handleLoadedApps:(NSArray *)loadedApps
{
    [_feed handleLoadedApps:loadedApps];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"NewRSSFeed"
     object:self];


}

- (void) failedNewRSSFeed:(NSNotification *) notification
{
    if (m_searchShouldBeginEditing)
    {
        m_searchShouldBeginEditing = FALSE;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                               target:self
                                                                                               action:@selector(onSearch:)];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
        [self createTopBanner];
    }

    if (m_isLoadingMoreData)
    {
        m_isLoadingMoreData = false;
        [self.tableView beginUpdates];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:LoadOlder] withRowAnimation:UITableViewRowAnimationLeft];
        [self.tableView endUpdates];
    }
}

- (void) receiveNewRSSFeed:(NSNotification *) notification
{
    [self setMenuOpen:false];
    
    [self updateSearchBlur:false];

    // tell our table view to reload its data, now that parsing has completed
    if (_feed.reset)
    {
        [self.tableView reloadData];
    }
    else
    {
        NSMutableArray *newIndexPaths = [[NSMutableArray alloc] init];
        for (int i=0; i<_feed.numNewFront; i++)
        {
            [newIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:Posts]];
        }
        for (int i=0; i<_feed.numNewBack; i++)
        {
            [newIndexPaths addObject:[NSIndexPath indexPathForRow:_feed.items.count-i-1 inSection:Posts]];
        }

        bool wasLoadingMoreData = m_isLoadingMoreData;
        m_isLoadingMoreData = false;
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationRight];
        if (wasLoadingMoreData)
        {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:LoadOlder] withRowAnimation:UITableViewRowAnimationLeft];
        }
        [self.tableView endUpdates];

    }
/*    NSArray *visibleCells = [self.tableView indexPathsForVisibleRows];
    if (visibleCells.count)
    {
        NSMutableArray *updateCells = [[NSMutableArray alloc] init];
        
        for(NSIndexPath *indexPath in visibleCells)
        {
            if (indexPath.section == Posts)
            {
                [updateCells addObject:indexPath];
            }
        }
        
        [self.tableView reloadRowsAtIndexPaths:updateCells
                          withRowAnimation:UITableViewRowAnimationRight];
    }
    else
*/    {
        [self.tableView reloadData];
    }
    [self loadImagesForOnscreenRows];

    [m_featureCell setNeedsDisplay];
    [m_featureCell updateFeed];
    
    [self.refreshControl endRefreshing];
    
    [self updateTargetPost];
}

- (void) updateTargetPost
{
    int targetPost = [[UserData get] getTargetPost];
    if (targetPost >= 0)
    {
        RSSFeed *rssFeed = [RSSFeed getInstance];
        
        SelectedItem *selItem = nil;
        
        for( CRSSItem *item in rssFeed.features)
        {
            if (item.postID == targetPost)
            {
                selItem = [SelectedItem alloc];
                selItem->isFavourite = false;
                selItem->isFeature = true;
                selItem->item = item;
                
                break;
            }
        }
        
        if (selItem == nil)
        {
            for( CRSSItem *item in rssFeed.items)
            {
                if (item.postID == targetPost)
                {
                    selItem = [SelectedItem alloc];
                    selItem->isFavourite = false;
                    selItem->isFeature = false;
                    selItem->item = item;
                    
                    break;
                }
            }
        }
        
        if (selItem != nil)
        {
            [self setMenuOpen:false];
            m_forcedDetailItem = selItem;
            
            [self performSegueWithIdentifier: @"showDetailManual" sender:self];
        }
        
        [[UserData get] setTargetPost:-1];
    }
}

- (void) updateMenuState:(NSNotification *) notification
{
   _btnMenu.tintColor = [UIColor whiteColor];
}

- (void) receiveViewPost:(NSNotification *) notification
{
//    CRSSItem *item = notification.object;
    [self setMenuOpen:false];
//    [self.detailViewController setDetailItem:item];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        SelectedItem *item = notification.object;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SetDetailItem" object:item];
    }
    else
    {
        m_forcedDetailItem = notification.object;
        
        [self performSegueWithIdentifier: @"showDetailManual" sender:self];
    //    [self.navigationController pushViewController:self.detailViewController animated:true];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];

}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    m_isInitialising = false;
    
    [self updateTargetPost];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
    
    NSInteger minItem = _feed.items.count;
    NSInteger maxItem = 0;
    if (_feed.items.count > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            if (indexPath.section == Posts)
            {
                minItem = MIN(indexPath.row, minItem);
                maxItem = MAX(indexPath.row, maxItem);
            }
        }
        
        minItem = MAX(minItem-3, 0);
        maxItem = MIN(maxItem+4, _feed.items.count);
        
        for (NSUInteger i=0; i<minItem; i++)
        {
            CRSSItem *appRecord = _feed.items[i];
            
            [appRecord freeImages];
        }
        for (NSUInteger i=maxItem; i<_feed.items.count; i++)
        {
            CRSSItem *appRecord = _feed.items[i];
            
            [appRecord freeImages];
        }
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (m_isLoadingMoreData)
        return Total_Sections;
    else
        return LoadOlder;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    int numPages = [_feed GetNumPages];
//    int page = [_feed GetPage];

    switch (section)
    {
        case LoadNewer:
//            if (page > 0)
//                return 1;
//            else
                return 0;
            break;
        case Features:
            if (_feed.features.count > 0)
                return 1;
            else
                return 0;
            break;
        case Posts:
            return _feed.items.count;
            break;
        case LoadOlder:
            if (m_isLoadingMoreData)
                return 1;
            else
                return 0;
            break;
        default:
            return 0;
            break;
            
    }
}

- (IBAction)onFavourite:(id)sender
{
    UIBarButtonItem *favBtn = (UIBarButtonItem *)sender;
    if (m_currentQuickMenuItem != -1)
    {
        CRSSItem *item = _feed.items[m_currentQuickMenuItem];
        NSMutableSet *favourites = [[UserData get] favourites];
        if ([favourites containsObject:item])
        {
/*            if (favBtn == m_btnFavourite)
            {
                [m_btnFavourite setSelected:false];
            }
            else*/
            {
//                [favBtn setBackButtonBackgroundImage:[UIImage imageNamed:@"icon_favourite_off"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
                favBtn.tintColor = [UIColor blackColor];
//                [favBtn setTintColor:[UIColor blackColor]];
            }
            [favourites removeObject:item];
        }
        else
        {
/*            if (favBtn == m_btnFavourite)
            {
                [m_btnFavourite setSelected:true];
            }
            else*/
            {
                favBtn.tintColor = [UIColor whiteColor];
//                [favBtn setBackButtonBackgroundImage:[UIImage imageNamed:@"icon_favourite_on"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//                [favBtn setTintColor:[UIColor whiteColor]];
            }
            [favourites addObject:item];
        }
        [[UserData get] onChanged];
        
        [self wobbleMenu];
    }
}

- (IBAction)onTweet:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        CRSSItem *item = _feed.items[m_currentQuickMenuItem];

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

- (IBAction)onFacebook:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        CRSSItem *item = _feed.items[m_currentQuickMenuItem];
        
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

- (IBAction)onViewPost:(id)sender
{
    if (m_currentQuickMenuItem >= 0)
    {
        CRSSItem *post = _feed.items[m_currentQuickMenuItem];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:m_currentQuickMenuItem inSection:Posts];
        PostCell *cell = (PostCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        UIView *view = cell.animateView;// [cell viewWithTag:8];
        UIImageView *imageView = cell.fullImage;//(UIImageView *)[cell viewWithTag:9];
        imageView.image = [post appIcon];
        [view setTransform:CGAffineTransformMakeTranslation(PAN_CLOSED_X, 0)];
        [imageView setAlpha:0.0f];
        [imageView setHidden:false];
        [UIView animateWithDuration:FAST_ANIMATION_DURATION
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [view setTransform:CGAffineTransformMakeTranslation(PAN_OPEN_X, 0)];
                             [imageView setAlpha:1.0f];
                         }
                         completion:^(BOOL finished) {
                             [self displayPost:m_currentQuickMenuItem];
                             [view setTransform:CGAffineTransformMakeTranslation(PAN_CLOSED_X, 0)];
                             [imageView setAlpha:0.0f];
                             [imageView setHidden:true];
                         }];

//        [self displayPost:m_currentQuickMenuItem];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int numPages = [_feed GetNumPages];
    int page = [_feed GetPage];

    switch (indexPath.section)
    {
        case LoadNewer:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoadMoreCell" forIndexPath:indexPath];
            cell.textLabel.text = [NSString stringWithFormat:@"Load Newer Posts (%d of %d)", page, numPages];
            return cell;
        }
        break;
                                   
        case LoadOlder:
        {
             UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoadMoreCell" forIndexPath:indexPath];
//             cell.textLabel.text = [NSString stringWithFormat:@"Load Older Posts (%d of %d)", page+2, numPages];
            return cell;
        }
        break;
                                    
        case Features:
        {
            bool newFeatureCell = m_featureCell == NULL;
            FeatureCell *cell = newFeatureCell ? [tableView dequeueReusableCellWithIdentifier:@"FeatureCellScroll" forIndexPath:indexPath] : m_featureCell;

            cell.rssFeed = _feed;
  
            if (newFeatureCell)
            {
                [cell updateFeed];
            
                m_featureCell = cell;
            }
            
            return cell;
        }
        break;
            
        case Posts:
        {
            PostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell" forIndexPath:indexPath];
            
            [cell setupIfNeeded];
            
            CRSSItem *object = _feed.items[indexPath.row];
            
            cell.title.text = [object title];
            cell.date.text = object.dateString;
            cell.blurredImage.image = [object getBlurredImage];
            cell.miniImage.image = object.iconImage;
            bool isExpanded = (m_currentQuickMenuItem == indexPath.row);
            cell.options.hidden = !isExpanded;

            if (isExpanded)
            {
                UIBarButtonItem *favourite = [cell.options items][1];
                if (favourite)
                {
                    bool isFavourite = [[[UserData get] favourites] containsObject:_feed.items[indexPath.row]];
                    
                    if (isFavourite)
                    {
                        [favourite setTintColor:[UIColor whiteColor]];
                    }
                    else
                    {
                        [favourite setTintColor:[UIColor blackColor]];
                    }
                }
            }

            //--- When initialising trigger all items to stream in images
            if (m_isInitialising)
            {
                [object requestImage:self];
            }
            return cell;
        }
        break;
    }
    
    return NULL;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath isEqual:m_expandedIndexPath])
    {
        return ExpandedSectionSize;
    }
    return SectionSize[indexPath.section];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void) loadImagesForOnscreenRows
{
    NSInteger minItem = _feed.items.count;
    NSInteger maxItem = 0;
    if (_feed.items.count > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            if (indexPath.section == Posts)
            {
                minItem = MIN(indexPath.row, minItem);
                maxItem = MAX(indexPath.row, maxItem);
            }
        }
    }
    
    minItem = MAX(minItem-3, 0);
    maxItem = MIN(maxItem+4, _feed.items.count);
    
    for (NSInteger i=minItem; i<maxItem; i++)
    {
        CRSSItem *appRecord = _feed.items[i];
        
        [appRecord requestImage:self];
/*        if (!appRecord.appIcon) // avoid the app icon download if the app already has an icon
        {
            [self startIconDownload:appRecord forIndexPath:indexPath];
        }*/

    }
}

-(void)snapView:(UIView *)view toX:(float)x animated:(BOOL)animated
{
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:FAST_ANIMATION_DURATION];
    }
    
    [view setTransform:CGAffineTransformMakeTranslation(x, 0)];
    
    if (animated) {
        [UIView commitAnimations];
    }
}

#pragma mark - Gesture recognizer delegate
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer
{
    UITableViewCell *cell = (UITableViewCell *)[panGestureRecognizer view];
    CGPoint translation = [panGestureRecognizer translationInView:[cell superview] ];
    return (fabs(translation.x) / fabs(translation.y) > 1) ? YES : NO;
}

- (IBAction)onPan:(UIPanGestureRecognizer *)sender
{
    CGPoint p = [sender locationInView:self.tableView];
    //CGPoint delta = [sender translationInView:self.view];
//    CGPoint delta = [sender velocityInView:self.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    if (indexPath.section == Posts)
    {
        PostCell *cell = (PostCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        UIView *view = cell.animateView;//[cell viewWithTag:8];
        UIImageView *imageView = cell.fullImage;//(UIImageView *)[cell viewWithTag:9];
        float threshold = (PAN_OPEN_X+PAN_CLOSED_X)/2.0;
        float vX = 0.0;
        float compare;

        {
            if (m_lastPannedIndexPath && (m_lastPannedIndexPath.section != indexPath.section || m_lastPannedIndexPath.row != indexPath.row))
            {
                PostCell *oldCell = (PostCell*)[self.tableView cellForRowAtIndexPath:m_lastPannedIndexPath];
                UIView *oldView = oldCell.animateView;//[oldCell viewWithTag:8];
                [self snapView:oldView toX:PAN_CLOSED_X animated:YES];
                UIImageView *oldImageView = oldCell.fullImage;//(UIImageView *)[oldCell viewWithTag:9];
                [oldImageView setAlpha:0.0f];
                [oldImageView setHidden:true];
                m_lastPannedIndexPath = nil;
                m_lastPannedX = 0;
            }
            
            switch (sender.state)
            {
                case UIGestureRecognizerStateBegan:
                    break;
                case UIGestureRecognizerStateEnded:
                    if (indexPath.section == Posts)
                    {
                    vX = (FAST_ANIMATION_DURATION/2.0)*[sender velocityInView:self.view].x;
                    compare = view.transform.tx + vX;
                    if (compare > threshold)
                    {
                        [self snapView:view toX:PAN_CLOSED_X animated:YES];
                        [imageView setAlpha:0.0f];
                        [imageView setHidden:true];
                        m_lastPannedIndexPath = nil;
                        m_lastPannedX = 0;
                    }
                    else
                    {
                        [imageView setHidden:false];
                        [UIView animateWithDuration:FAST_ANIMATION_DURATION
                                delay:0.0f
                                options:UIViewAnimationOptionCurveEaseInOut
                                animations:^{
                                             [view setTransform:CGAffineTransformMakeTranslation(PAN_OPEN_X, 0)];
                                             [imageView setAlpha:1.0f];
                                         }
                                         completion:^(BOOL finished) {
                                            [self displayPost:indexPath.row];
                                             [view setTransform:CGAffineTransformMakeTranslation(PAN_CLOSED_X, 0)];
                                             [imageView setAlpha:0.0f];
                                             [imageView setHidden:true];
                                         }];
    //                    [self snapView:view toX:PAN_OPEN_X animated:YES];
    //                    [imageView setAlpha:1.0f];
    //                    [imageView setHidden:false];
                        m_lastPannedIndexPath = indexPath;
                        m_lastPannedX = view.transform.tx;
    //                    [UIView setAnimationDidStopSelector:@selector(displayPost:(indexPath.row):)];

    //                    [self displayPost:indexPath.row];
                    }
                    }
                    break;
                case UIGestureRecognizerStateChanged:
                    if (indexPath.section == Posts)
                    {
                        CRSSItem *curItem = _feed.items[indexPath.row];
                        imageView.image = curItem.appIcon;
                        [imageView setHidden:false];
                        
                        compare = /*m_lastPannedX+*/[sender translationInView:self.view].x;
                        if (compare > PAN_CLOSED_X)
                            compare = PAN_CLOSED_X;
                        else if (compare < PAN_OPEN_X)
                            compare = PAN_OPEN_X;
                        float alpha = compare / PAN_OPEN_X;
                        [view setTransform:CGAffineTransformMakeTranslation(compare, 0)];
                        [imageView setAlpha:alpha];
                        
                        m_lastPannedIndexPath = indexPath;
                    }
                    break;
                default:
                    break;
            }
    /*        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (cell)
            {
                CGRect newFrame = cell.frame;
                newFrame.origin.x += delta.x;
                cell.frame = newFrame;
            }*/
        }
    }
}

-(void)doExpandPost:(NSIndexPath*)indexPath
{
    if(indexPath && (indexPath.section == Posts))
    {
        if (![indexPath isEqual:m_expandedIndexPath])
        {
            PostCell *cell = (PostCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            UIToolbar *toolbarMenu = cell.options;//(UIToolbar *) [cell viewWithTag:6];
            [toolbarMenu setHidden:false];
            UIBarButtonItem *favourite = [toolbarMenu items][1];
//            UIBarButtonItem *favourite = (UIBarButtonItem*)[toolbarMenu viewWithTag:7];
            if (favourite)
            {
                bool isFavourite = [[[UserData get] favourites] containsObject:_feed.items[indexPath.row]];

                if (isFavourite)
                {
                    [favourite setTintColor:[UIColor whiteColor]];
                }
                else
                {
                    [favourite setTintColor:[UIColor blackColor]];
                }
            }

            m_currentQuickMenuItem = indexPath.row;
            m_expandedIndexPath = indexPath;
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
        }
        else
        {
            PostCell *cell = (PostCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell.options setHidden:true];

            m_currentQuickMenuItem = -1;
            m_expandedIndexPath = nil;
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
        }
    }
}

-(void)displayPost:(NSInteger)postID
{
    SelectedItem *item = [SelectedItem alloc];
    item->isFavourite = false;
    item->isFeature = false;
    item->item = _feed.items[postID];
    
    m_forcedDetailItem = item;
    
    [self performSegueWithIdentifier: @"showDetailManual" sender:self];
}

-(void)swipePost:(UISwipeGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    
    if(indexPath && (indexPath.section == Posts))
    {
        if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionLeft)
        {
            [self displayPost:indexPath.row];
        }
    }
}


-(void)expandPost:(UISwipeGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    
    if(indexPath && (indexPath.section == Posts))
    {
        if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight)
        {
            if (![indexPath isEqual:m_expandedIndexPath])
            {
                PostCell *cell = (PostCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                
                [cell.options setHidden:false];
                
/*                [cell.contentView insertSubview:m_quickMenu atIndex:0];
//                [cell insertSubview:m_quickMenu aboveSubview:<#(UIView *)#>
//                [self.tableView insertSubview:m_quickMenu belowSubview:cell];
                
                CGRect initialFrame = cell.frame;
                initialFrame.origin.y = cell.frame.size.height + cell.frame.origin.y;
                initialFrame.size.height = 0;
                CGRect newFrame = initialFrame;
                newFrame.size.height = 40.0f;
                
                
                NSLayoutConstraint *myConstraint =[NSLayoutConstraint
                                                   constraintWithItem:m_quickMenu
                                                   attribute:NSLayoutAttributeBottom
                                                   relatedBy:NSLayoutRelationEqual
                                                   toItem:cell.contentView
                                                   attribute:NSLayoutAttributeBottom
                                                   multiplier:1.0                                                                      
                                                   constant:0];
                [cell.contentView addConstraint:myConstraint];
                
                NSLayoutConstraint *myConstraint2 =[NSLayoutConstraint
                                                   constraintWithItem:m_quickMenu
                                                   attribute:NSLayoutAttributeTop
                                                   relatedBy:NSLayoutRelationEqual
                                                   toItem:[cell.contentView viewWithTag:5]
                                                   attribute:NSLayoutAttributeBottom
                                                   multiplier:1.0
                                                   constant:0];
                [cell.contentView addConstraint:myConstraint2];*/
                //                [m_quickMenu addConstraint:[NSLayoutAttributeBaseline ]

//                m_quickMenu.frame = initialFrame;
//                [UIView animateWithDuration:0.3f animations:^{[cell setFrame:newFrame];[m_quickMenu setFrame:newFrame];}];

                m_currentQuickMenuItem = indexPath.row;
                m_expandedIndexPath = indexPath;
                [self.tableView beginUpdates];
                [self.tableView endUpdates]; //Yeah, that old trick to animate cell expand/collapse
            }

/*            if (![indexPath isEqual:m_expandedIndexPath])
            {
                NSMutableArray *updatedCells = [[NSMutableArray alloc] init];
                if (m_expandedIndexPath != nil)
                {
                    [updatedCells addObject:m_expandedIndexPath];
                }

                m_expandedIndexPath = indexPath;
                [updatedCells addObject:indexPath];

                [self.tableView reloadRowsAtIndexPaths:updatedCells withRowAnimation:UITableViewRowAnimationFade];
            }*/
        }
        else
        {
            NSIndexPath *oldIndexPath = m_expandedIndexPath;
            m_expandedIndexPath = nil;
            m_currentQuickMenuItem = -1;

            if (oldIndexPath)
            {
                [self.tableView beginUpdates];
                [self.tableView endUpdates]; //Yeah, that old trick to animate cell expand/collapse
//                [self.tableView reloadRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case LoadNewer:
//            [_feed LoadPage:[_feed GetPage]-1];
            break;
        case LoadOlder:
//            [_feed LoadPage:[_feed GetPage]+1];
            break;
        case Posts:
//            [self doExpandPost:indexPath];
            
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            {
                SelectedItem *item = [SelectedItem alloc];
                item->isFavourite = false;
                item->isFeature = false;
                item->item = _feed.items[indexPath.row];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SetDetailItem" object:item];


//                CRSSItem *object = _feed.items[indexPath.row];
//                [self.detailViewController setDetailItem:object list:_feed.items];
            }
            break;
    }
}

-(void)move:(UIPanGestureRecognizer *)sender
{
    CGPoint p = [sender locationInView:self.tableView];
    CGPoint delta = [sender translationInView:self.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    
    if (indexPath.section == Posts)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell)
        {
            CGRect newFrame = cell.frame;
            newFrame.origin.x += delta.x;
            cell.frame = newFrame;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        CRSSItem *object = _feed.items[indexPath.row];
        [[segue destinationViewController] setDetailItem:object list:_feed.items];
    }
    else if ([[segue identifier] isEqualToString:@"showDetailFeature"])
    {
        if (m_featureCell)
        {
            [m_featureCell prepareForSegue:segue sender:sender];
        }
    }
    else if ([[segue identifier] isEqualToString:@"showDetailManual"])
    {
        if (m_forcedDetailItem->isFavourite)
        {
            NSArray *favouriteList = [[[UserData get] favourites] allObjects];
            [[segue destinationViewController] setDetailItem:m_forcedDetailItem->item list:favouriteList];
        }
        else if (m_forcedDetailItem->isFeature)
        {
            [[segue destinationViewController] setDetailItem:m_forcedDetailItem->item list:_feed.features];
        }
        else
        {
            [[segue destinationViewController] setDetailItem:m_forcedDetailItem->item list:_feed.items];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_feed.items.count && !m_isInitialising)
    {
    if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height)
    {
        if (!m_isLoadingMoreData)
        {
            m_isLoadingMoreData = true;

            [self.tableView beginUpdates];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:LoadOlder] withRowAnimation:UITableViewRowAnimationRight];
            [self.tableView endUpdates];

            [_feed LoadPage:[_feed GetPage]+1];
        }
    }
    }
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}

// Search bar functionality


- (void) spinWithOptions: (UIViewAnimationOptions) options {
    // this spin completes 360 degrees every 2 seconds
    [UIView animateWithDuration: 0.5f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         m_searchSpinner.transform = CGAffineTransformRotate(m_searchSpinner.transform, M_PI / 2);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             // if flag still set, keep spinning with constant speed
                             [self spinWithOptions: UIViewAnimationOptionCurveLinear];
                         }
                     }];
}

-(void) updateSearchBlur:(Boolean) enable
{
    if (enable)
    {
        [self.view.superview addSubview:m_searchOverlay];
        
        [UIView beginAnimations:@"FadeIn" context:nil];
        [UIView setAnimationDuration:0.5];
        m_searchOverlay.alpha = 0.6;
        [UIView commitAnimations];
    }
    else
    {
        
        if (m_searchOverlay.alpha > 0)
        {
            [UIView animateWithDuration:m_searchOverlay.alpha animations:^{
                m_searchOverlay.alpha = 0.0;
                m_searchSpinner.alpha = 0.0;
            } completion:^(BOOL finished) {
                [m_searchOverlay removeFromSuperview];
            }];
        }
        else
        {
            m_searchOverlay.alpha = 0;
            m_searchSpinner.alpha = 0.0;
            [m_searchOverlay removeFromSuperview];
        }
    }
}

- (IBAction)onSearch:(id)sender
{
    if (m_searchShouldBeginEditing)
    {
        [self.navigationItem.titleView resignFirstResponder];
        
        [self createTopBanner];
        
        m_searchShouldBeginEditing = FALSE;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                               target:self
                                                                                               action:@selector(onSearch:)];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
        
        [_feed clearSearch];
    }
    else
    {
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        [searchBar sizeToFit];
        searchBar.delegate = self;
        self.navigationItem.titleView = searchBar;
        
        m_searchShouldBeginEditing = true;
        [searchBar becomeFirstResponder];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                               target:self
                                                                                               action:@selector(onSearch:)];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    }
    
    [self updateSearchBlur:m_searchShouldBeginEditing];
}

- (void)searchBar:(UISearchBar *)bar textDidChange:(NSString *)searchText
{
    if(![bar isFirstResponder])
    {
        // user tapped the 'clear' button
        m_searchShouldBeginEditing = NO;
        
        [_feed clearSearch];
        
        [self createTopBanner];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                               target:self
                                                                                               action:@selector(onSearch:)];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    }
}


- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
    // reset the shouldBeginEditing BOOL ivar to YES, but first take its value and use it to return it from the method call
    BOOL boolToReturn = m_searchShouldBeginEditing;
    m_searchShouldBeginEditing = YES;
    return boolToReturn;
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
//    showAudio = [_filterAudio isOn];
//    showVideo = [_filterVideo isOn];
//    showText  = [_filterText isOn];
    
    [[RSSFeed getInstance] FilterJSON:searchBar.text showAudio:true showVideo:true showText:true];
    
    [UIView animateWithDuration:0.5 animations:^{
        m_searchOverlay.alpha = 0.95;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            m_searchSpinner.alpha = 1.0;
        } completion:^(BOOL finished) {
            [self spinWithOptions:UIViewAnimationOptionCurveEaseIn];
        }];
    }];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    [_feed LoadFeed];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"NewRSSFeed"
     object:self];

    [self updateSearchBlur:false];

    [self createTopBanner];
}


@end
