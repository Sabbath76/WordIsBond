//
//  MasterViewController.m
//  testapp
//
//  Created by Jose Lopes on 30/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

#import "RSSParser.h"
#import "RSSFeed.h"

#import "FeatureCell.h"
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
    30, 183, 80, 40
};

@interface MasterViewController ()
{
    __weak IBOutlet UIButton *m_btnFavourite;
    
    RSSFeed *_feed;

    RSSParser *m_parser;
    
    FeatureCell *m_featureCell;
    
    FeatureViewController *m_featuresController;
    
    SelectedItem *m_forcedDetailItem;
    
    UIView *m_quickMenu;
    
    int m_currentQuickMenuItem;
    
    bool m_isLoadingMoreData;
}


- (void)startIconDownload:(CRSSItem *)appRecord forIndexPath:(NSIndexPath *)indexPath;    // thequeue to run our "ParseOperation"

@end

@implementation MasterViewController

@synthesize imageDownloadsInProgress, toolbar;

- (void) setMenuOpen:(bool)state
{
    CGRect destination = self.navigationController.view.superview.superview.frame;
    
    if (state)
    {
        destination.origin.x = 270;
        _btnMenu.tintColor = [UIColor blackColor];
        
        [self.tableView setUserInteractionEnabled:false];
    }
    else
    {
        destination.origin.x = 0;
        _btnMenu.tintColor = [UIColor whiteColor];
        
        [self.tableView setUserInteractionEnabled:true];
    }
    
    [UIView beginAnimations:@"Bringing up menu" context:nil];
    self.navigationController.view.superview.superview.frame = destination;
    [UIView commitAnimations];
}

- (void) selectDetail:(CRSSItem *)item
{
    [self setMenuOpen:false];
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

- (IBAction)onSearch:(id)sender
{
    [self setMenuOpen:true];
}

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    
    m_parser = [RSSParser alloc];
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
    
    _feed = [RSSFeed getInstance];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
//    m_featureCell = [FeatureCell alloc];
//    m_featureCell.rssFeed = _feed;
//    m_featuresController = [FeatureViewController alloc];
//    [m_featuresController setFeed:_feed];
    
    // create the queue to run our ParseOperation
//    self.m_queue = [[[NSOperationQueue alloc] init] autorelease];

    //--- JSON Only
//    [_feed LoadFeed];
    
    //--- RSS Feed
//    NSString *url = @"http://www.thewordisbond.com/feed/mobile/?format=xml";
/*    NSString *url = @"http://www.thewordisbond.com/feed/tablet/?format=xml";
    [m_parser startParse:url completionHandler:^(NSArray *appList) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self handleLoadedApps:appList];
            
        });
 
//        self.m_queue = nil;   // we are finished with the queue and our ParseOperation
    }];*/
    
//Huh?    [self setNeedsStatusBarAppearanceUpdate];
    
    m_isLoadingMoreData = false;
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_banner_logo"]];
    
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
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(receiveCloseMenu:)
//                                                 name:@"CloseMenu"
//                                               object:nil];
    
    
/*
 
 Makka munda.
 Hello there!
 I like to mohgli mohgli.
 
 Oh Poo!
 
 Hello painted dog!
 Who painted you anyway?
 Was it a naughty cat?
 
 Brulbrrulbrulbrbulrbrulbrulbrrp!
 
 Pifftlerpahpacutpennoo
 
 How much wood would a woodchuck chuck if a woodchuck could chuck wood?
 
 Red lorry yellow lorry Red lorry yellow lorry Red lorry yellow lorry Red lorry yellow lorry.
 
 She sells seashells on the seashore
 
 Luke luck licks lakes
 Luke Luke's duck licks lakes?
 
 Polar bears are smashing their heads against the ice
 
 my memery is gone!
 
 EeeeeeeeeEeeeeeeeeeeeEeeeeeee
 
 I'm stupid
 
 You are a poo
 
 OH POO. I really hate myself!
 */
    
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    [refresh setTintColor:[UIColor whiteColor]];

    [refresh addTarget:self action:@selector(loadNewer) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;
    
    UISwipeGestureRecognizer *swipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [swipeRecognizerLeft setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.tableView addGestureRecognizer:swipeRecognizerLeft];

    UISwipeGestureRecognizer *swipeRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [swipeRecognizerRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.tableView addGestureRecognizer:swipeRecognizerRight];

/*    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 2.0; //seconds
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];*/
    
    m_quickMenu = [[[NSBundle mainBundle] loadNibNamed:@"PostQuickMenu" owner:self options:nil] objectAtIndex:0];
}

- (void) loadNewer
{
    int newPage = MAX([_feed GetPage]-1, 0);
    [_feed LoadPage:newPage];
}

- (void)startIconDownload:(CRSSItem *)appRecord forIndexPath:(NSIndexPath *)indexPath
{
    [IconDownloader download:appRecord delegate:self];
/*    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.appRecord = appRecord;
        iconDownloader.indexPathInTableView = indexPath;
        iconDownloader.delegate = self;
        iconDownloader.isItem = true;
        [imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload];
//        [iconDownloader release];
    }*/
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
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                UIImageView *imgView = (UIImageView *)[cell viewWithTag:2];
                UIImageView *imgViewMini = (UIImageView *)[cell viewWithTag:4];
                imgView.image = iconDownloader.appRecord.blurredImage;
                imgViewMini.image = iconDownloader.appRecord.appIcon;

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
}

- (void) receiveViewPost:(NSNotification *) notification
{
//    CRSSItem *item = notification.object;
    [self setMenuOpen:false];
//    [self.detailViewController setDetailItem:item];
    m_forcedDetailItem = notification.object;
    
    [self performSegueWithIdentifier: @"showDetailManual" sender:self];
//    [self.navigationController pushViewController:self.detailViewController animated:true];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if (m_currentQuickMenuItem != -1)
    {
        CRSSItem *item = _feed.items[m_currentQuickMenuItem];
        NSMutableSet *favourites = [[UserData get] favourites];
        if ([favourites containsObject:item])
        {
            [m_btnFavourite setSelected:false];
            [favourites removeObject:item];
        }
        else
        {
            [m_btnFavourite setSelected:true];
            [favourites addObject:item];
        }
        [[UserData get] onChanged];
    }
}

- (IBAction)onTweet:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        CRSSItem *item = _feed.items[m_currentQuickMenuItem];

        [mySLComposerSheet setInitialText:@"Found a dope post on WIB"];
    
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
        
        [mySLComposerSheet setInitialText:@"Found a dope post on WIB"];
        
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
            cell.detailViewController = _detailViewController;
           
/*            CALayer *_maskingLayer = [CALayer layer];
            _maskingLayer.frame = cell.bounds;
            UIImage *stretchableImage = (id)[UIImage imageNamed:@"corner"];
            
            _maskingLayer.contents = (id)stretchableImage.CGImage;
            _maskingLayer.contentsScale = [UIScreen mainScreen].scale; //<-needed for the retina display, otherwise our image will not be scaled properly
            _maskingLayer.contentsCenter = CGRectMake(15.0/stretchableImage.size.width,15.0/stretchableImage.size.height,5.0/stretchableImage.size.width,5.0f/stretchableImage.size.height);

            [cell.layer setMask:_maskingLayer];
            */
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
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell" forIndexPath:indexPath];
            
            CRSSItem *object = _feed.items[indexPath.row];
            
//            [cell.layer setMask:_maskingLayer];

            UILabel *label = (UILabel *)[cell viewWithTag:1];
            label.text = [object title];
            UIImageView *imgView = (UIImageView *)[cell viewWithTag:2];
            UIImageView *imgIcon = (UIImageView *)[cell viewWithTag:3];
            UIImageView *imgViewMini = (UIImageView *)[cell viewWithTag:4];
            UILabel *labelDate = (UILabel *)[cell viewWithTag:5];
            labelDate.text = object.dateString;

            imgView.image = object.blurredImage;
            imgViewMini.image = object.appIcon;
            
            if (imgViewMini)
            {
                CALayer *_maskingLayer = [CALayer layer];
                _maskingLayer.frame = imgViewMini.bounds;
                UIImage *stretchableImage = (id)[UIImage imageNamed:@"cornerfull"];
                
                _maskingLayer.contents = (id)stretchableImage.CGImage;
                _maskingLayer.contentsScale = [UIScreen mainScreen].scale; //<-needed for the retina display, otherwise our image will not be scaled properly
                _maskingLayer.contentsCenter = CGRectMake(15.0/stretchableImage.size.width,15.0/stretchableImage.size.height,5.0/stretchableImage.size.width,5.0f/stretchableImage.size.height);

                [imgViewMini.layer setMask:_maskingLayer];
            }


            switch (object.type)
            {
                case Audio:
                    imgIcon.image = [UIImage imageNamed:@"audio"];
                   break;
                case Video:
                    imgIcon.image = [UIImage imageNamed:@"video"];
                    break;
                case Text:
                    imgIcon.image = [UIImage imageNamed:@"text"];
                    break;
            }
            
/*            [UIView animateWithDuration:1.0
                    delay: 0.0
                    options: UIViewAnimationOptionCurveEaseIn
                    animations:^{
                                 [cell.frame.size.height = 0.0;
                             }
                             completion:^(BOOL finished){
                                 // Wait one second and then fade in the view
                                 [UIView animateWithDuration:1.0
                                                       delay: 1.0
                                                     options:UIViewAnimationOptionCurveEaseOut
                                                  animations:^{
                                                      thirdView.alpha = 1.0;
                                                  }
                                                  completion:nil];
                             }];*/
            return cell;
        }
        break;
    }
    
    return NULL;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    int minItem = _feed.items.count;
    int maxItem = 0;
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
    
    for (int i=minItem; i<maxItem; i++)
    {
        CRSSItem *appRecord = _feed.items[i];
        
        [appRecord requestImage:self];
/*        if (!appRecord.appIcon) // avoid the app icon download if the app already has an icon
        {
            [self startIconDownload:appRecord forIndexPath:indexPath];
        }*/

    }
}

-(void)handleLongPress:(UISwipeGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    if (indexPath.section == Posts)
    {
        if (indexPath == nil)
        {
            //--- Cancel existing?
        }
        else
        {
            NSLog(@"long press on table view at row %d", indexPath.row);
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (cell)
            {
                if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight)
                {
                    if (m_currentQuickMenuItem != indexPath.row)
                    {
                        CGRect initialFrame = cell.frame;
                        CGRect newMenuFrame = cell.frame;
                        CGRect newFrame = cell.frame;
                        initialFrame.origin.x = 0;
                        initialFrame.size.width = 0;
                        newMenuFrame.size.width = 100.0f;
                        newFrame.origin.x = 100;
                        
                        // Add the side swipe view to the table below the cell
                        [self.tableView insertSubview:m_quickMenu belowSubview:cell];
                        
                        CRSSItem *item = _feed.items[indexPath.row];
                        bool isFavourite = [[[UserData get] favourites] containsObject:item];
                        
                        if (m_currentQuickMenuItem >= 0)
                        {
                            NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:m_currentQuickMenuItem inSection:Posts];
                            UITableViewCell *oldcell = [self.tableView cellForRowAtIndexPath:oldIndexPath];

                            CGRect oldClosedFrame = oldcell.frame;
                            oldClosedFrame.origin.x = 0;
                            CGRect oldClosedMenuFrame = oldcell.frame;
                            oldClosedMenuFrame.origin.x = 0;
                            oldClosedMenuFrame.size.width = 0;
                            [UIView animateWithDuration:0.1f
                              animations:^
                              {
                                  [oldcell setFrame:oldClosedFrame];
                                  [m_quickMenu setFrame:oldClosedMenuFrame];
                              }
                              completion:^(BOOL finished)
                              {
                                  [m_quickMenu setFrame:initialFrame];
                                  [m_btnFavourite setSelected:isFavourite];
                                  [UIView animateWithDuration:0.2f animations:^{[cell setFrame:newFrame];[m_quickMenu setFrame:newMenuFrame];}];
                              }
                              ];
                        }
                        else
                        {
                            m_quickMenu.frame = initialFrame;
                            [m_btnFavourite setSelected:isFavourite];
                            [UIView animateWithDuration:0.3f animations:^{[cell setFrame:newFrame];[m_quickMenu setFrame:newMenuFrame];}];
                        }
                        
                        m_currentQuickMenuItem = indexPath.row;
                    }
                }
                else
                {
                    if (indexPath.row == m_currentQuickMenuItem)
                    {
                        CGRect newFrame = cell.frame;
                        newFrame.origin.x = 0;
                        CGRect newMenuFrame = cell.frame;
                        newMenuFrame.origin.x = 0;
                        newMenuFrame.size.width= 0;
                        [UIView animateWithDuration:0.3f animations:^{[cell setFrame:newFrame];[m_quickMenu setFrame:newMenuFrame];}];
                        m_currentQuickMenuItem = -1;
                    }
                }
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
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            {
                CRSSItem *object = _feed.items[indexPath.row];
                [self.detailViewController setDetailItem:object list:_feed.items];
            }
            break;
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
        else
        {
            [[segue destinationViewController] setDetailItem:m_forcedDetailItem->item list:_feed.items];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_feed.items.count)
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

@end
