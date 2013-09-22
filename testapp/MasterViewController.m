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


#import <MediaPlayer/MediaPlayer.h>



@interface MasterViewController ()
{
    RSSFeed *_feed;
//    NSMutableArray *_objects;
    RSSParser *m_parser;
    
    FeatureCell *m_featureCell;
    
    FeatureViewController *m_featuresController;

    MPMoviePlayerController *m_player;
//    NSOperationQueue        *m_queue;
}

/*
MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:    [NSURL URLWithString:@"YOUR URL"]];
player.movieSourceType = MPMovieSourceTypeStreaming;
player.view.hidden = YES;
[self.view addSubview:player.view];
[player prepareToPlay];
[player play];
*/

- (void)startIconDownload:(CRSSItem *)appRecord forIndexPath:(NSIndexPath *)indexPath;    // thequeue to run our "ParseOperation"

@end

@implementation MasterViewController

@synthesize imageDownloadsInProgress, toolbar;

//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//
//    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
//    self.tableView.rowHeight = kCustomRowHeight;
//}

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    
    m_parser = [RSSParser alloc];
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
    
    _feed = [RSSFeed getInstance];
    
//    m_featureCell = [FeatureCell alloc];
//    m_featureCell.rssFeed = _feed;
//    m_featuresController = [FeatureViewController alloc];
//    [m_featuresController setFeed:_feed];
    
    // create the queue to run our ParseOperation
//    self.m_queue = [[[NSOperationQueue alloc] init] autorelease];
    
    NSString *url = @"http://www.thewordisbond.com/feed/tablet/?format=xml";
    [m_parser startParse:url completionHandler:^(NSArray *appList) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self handleLoadedApps:appList];
            
        });
        
//        self.m_queue = nil;   // we are finished with the queue and our ParseOperation
    }];
    
    [super awakeFromNib];
}

- (void)startIconDownload:(CRSSItem *)appRecord forIndexPath:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
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
    }
}

// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
    if ((iconDownloader != nil) && iconDownloader.isItem)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        
        // Display the newly loaded image
        UIImageView *imgView = (UIImageView *)[cell viewWithTag:2];
        imgView.image = iconDownloader.appRecord.appIcon;
//        cell.imageView.image = iconDownloader.appRecord.appIcon;
//    }
    
    // Remove the IconDownloader from the in progress list.
    // This will result in it being deallocated.
    [imageDownloadsInProgress removeObjectForKey:iconDownloader.indexPathInTableView];
    }
}

// -------------------------------------------------------------------------------
//  handleLoadedApps:notif
// -------------------------------------------------------------------------------
- (void)handleLoadedApps:(NSArray *)loadedApps
{
//    [self.appRecords addObjectsFromArray:loadedApps];
    
    [_feed handleLoadedApps:loadedApps];
//    _objects = [[NSMutableArray alloc] init];
//    for (CRSSItem *item in loadedApps)
//    {
//        [_objects insertObject:item atIndex:0];
//    }
    
    // tell our table view to reload its data, now that parsing has completed
    [self.tableView reloadData];
    [self loadImagesForOnscreenRows];
//    [m_featuresController updateFeed];
//    [m_featureCell updateFeed];
    
    //FeatureCell *cell = [self.tableView cellForRowAtIndexPath:[iconDownloader.indexPathInTableView];
    [m_featureCell setNeedsDisplay];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"NewRSSFeed"
     object:self];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    self.navigationItem.leftBarButtonItem = self.editButtonItem;

//    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(insertNewObject:)];
//    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    [self createToolbar];
 //   self.tableView.transform = CGAffineTransformMakeRotation(M_PI / -2.0); //Convert 90 degrees to radians
 //   self.tableView.frame = (CGRect){ 0, 0, 320, 200};

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)insertNewObject:(id)sender
//{
//    if (!_objects) {
//        _objects = [[NSMutableArray alloc] init];
//    }
//    [_objects insertObject:[NSDate date] atIndex:0];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        if (_feed.features.count > 0)
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return _feed.items.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        FeatureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FeatureCellScroll" forIndexPath:indexPath];

//        if (m_featureCell == NULL)
//        {
//            m_featureCell = [[FeatureCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FeatureCell"];
//        }

        cell.rssFeed = _feed;
        cell.detailViewController = _detailViewController;
        
        cell.horizontalTableView.delegate = cell;
        cell.horizontalTableView.dataSource = cell;
        
//        printf cell.frame.size
        
//        UITableView *featureTable = (UITableView *)[m_featureCell viewWithTag:1];

//        CGRect frame = cell.horizontalTableView.frame;
////        cell.horizontalTableView.transform = CGAffineTransformMakeRotation(M_PI / -2.0); //Convert 90 degrees to radians
/////        cell.horizontalTableView.frame = (CGRect){ 0, 0, 320, 200};
//        cell.horizontalTableView.frame = frame;
        
        NSLog(@"MakeFeatureCell%@", NSStringFromCGRect(cell.frame));
        NSLog(@"%@", NSStringFromCGRect(cell.horizontalTableView.frame));

//        featureTable.delegate = m_featuresController;
//        featureTable.dataSource = m_featuresController;
//        CGRect frame = featureTable.frame;
//        featureTable.transform = CGAffineTransformRotate(stressTblView.transform, M_PI / 2);
//        featureTable.frame = frame;
        
        [cell setNeedsDisplay];
        
        [cell updateFeed];
        
        m_featureCell = cell;
        
        return cell;
    }
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell" forIndexPath:indexPath];
        
        CRSSItem *object = _feed.items[indexPath.row];
        
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        label.text = [object title];
        //cell.textLabel.text = [object title];
//        if (object.appIcon)
        {
            UIImageView *imgView = (UIImageView *)[cell viewWithTag:2];
            imgView.image = object.appIcon;
        }
        UIButton *mediaButton = (UIButton *)[cell viewWithTag:3];
        if (mediaButton)
        {
            [mediaButton setHidden:(object.mediaURLString == NULL)];
        }
        
 ///       cell.transform = CGAffineTransformMakeRotation(-M_PI / -2.0); //Convert 90 degrees to radians
//        cell.frame = (CGRect){ 0, 0, 320, 200};


        return cell;
    }
}

- (void)createToolbar
{
    // Initialization code
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIToolbarDragger *EmailBtn = [[UIToolbarDragger alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
    [EmailBtn setBackgroundImage:[UIImage imageNamed:@"audioplaying.png"] forState:UIControlStateNormal];
    EmailBtn.showsTouchWhenHighlighted = YES;
    
    UIBarButtonItem *EmailBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:EmailBtn];
    NSArray *buttons = [NSArray arrayWithObjects:spacer, EmailBarButtonItem, spacer, nil];
    [self setToolbarItems:buttons];

//    UIBarButtonItem *playItem = [[UIBarButtonItem alloc] initWithTitle:@"Play" style:UIBarButtonItemStyleBordered target:self action:@selector(goToChangeCategory:)];
//    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
//    NSArray *buttonItems = [NSArray arrayWithObjects:spacer, playItem, spacer, nil];
//    [self setToolbarItems:buttonItems];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        return 140;
    }
    else
    {
        return 80;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        [_objects removeObjectAtIndex:indexPath.row];
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
//    }
//}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void) loadImagesForOnscreenRows
{
    if (_feed.items.count > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            if (indexPath.section == 1)
            {
                CRSSItem *appRecord = _feed.items[indexPath.row];
            
                if (!appRecord.appIcon) // avoid the app icon download if the app already has an icon
                {
                    [self startIconDownload:appRecord forIndexPath:indexPath];
                }
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        CRSSItem *object = _feed.items[indexPath.row];
        self.detailViewController.detailItem = object;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        CRSSItem *object = _feed.items[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
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
