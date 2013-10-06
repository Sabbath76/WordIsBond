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

@synthesize horizontalTableView, scrollView, rssFeed, detailViewController;
@synthesize imageView1, imageView2, imageView3, imageView4;

//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//
//    self.horizontalTableView.transform = CGAffineTransformMakeRotation(M_PI/-2);
//    self.horizontalTableView.frame = (CGRect){ 0, 100, 320, 200};
//}

- (void)awakeFromNib
{
    // Initialization code
    CGRect oldFrameSelf = self.frame;
    // Initialization code
    CGRect oldFrameScroll = self.scrollView.frame;

    // Initialization code
/*
    CGRect oldFrame = self.horizontalTableView.frame;
    self.horizontalTableView.transform = CGAffineTransformMakeRotation(M_PI/-2);
   
    NSLog(@"awakeFromNib:%@", NSStringFromCGRect(self.horizontalTableView.frame));
    NSLog(@"%@", NSStringFromCGRect(oldFrame));
    
//    self.horizontalTableView.frame = oldFrame;
    horizontalTableView.frame = CGRectMake(0, 500,horizontalTableView.frame.size.width, horizontalTableView.frame.size.height);
*/
    ///    self.horizontalTableView.frame = (CGRect){ 0, 100, 320, 200};
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

    
//    self.horizontalTableView.frame = (CGRect){ 0, 0, 100, 320};
    
///    [self setTranslatesAutoresizingMaskIntoConstraints:FALSE];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(onIconLoaded:)
//                                                 name:@"IconLoaded"
//                                               object:nil];

}

- (void) viewDidAppear
{
    [self updateFeed];
 
}




//- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
//{
//    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
//    if (self) {
//        // Initialization code
//        self.horizontalTableView.transform = CGAffineTransformMakeRotation(M_PI/-2);
//        self.horizontalTableView.frame = (CGRect){ 0, 0, 320, 200};
//    }
//    return self;
//}

//- (id)initWithFrame:(CGRect)frame
//{
//    if ((self = [super initWithFrame:frame]))
//    {
///        self.horizontalTableView.transform = CGAffineTransformMakeRotation(M_PI/-2);
///        self.horizontalTableView.frame = (CGRect){ 0, 100, 320, 200};
//        self.horizontalTableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, kCellHeight, kTableLength)] autorelease];
//        self.horizontalTableView.showsVerticalScrollIndicator = NO;
//        self.horizontalTableView.showsHorizontalScrollIndicator = NO;
//        self.horizontalTableView.transform = CGAffineTransformMakeRotation(-M_PI * 0.5);
//        [self.horizontalTableView setFrame:CGRectMake(kRowHorizontalPadding * 0.5, kRowVerticalPadding * 0.5, kTableLength - kRowHorizontalPadding, kCellHeight)];
//
//        self.horizontalTableView.rowHeight = kCellWidth;
//        self.horizontalTableView.backgroundColor = kHorizontalTableBackgroundColor;
//
//        self.horizontalTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
//        self.horizontalTableView.separatorColor = [UIColor clearColor];
//
//        self.horizontalTableView.dataSource = self;
//        self.horizontalTableView.delegate = self;
//        [self addSubview:self.horizontalTableView];
///    }
    
//    return self;
//}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 320;
}

- (CGFloat)tableView:(UITableView *)tableView widthForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSLog(@"numRows:%@", NSStringFromCGRect(self.frame));
    NSLog(@"numRows:%@", NSStringFromCGRect(self.horizontalTableView.frame));

    return rssFeed.features.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil) {
//        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
//    }
    
    CRSSItem *rssItem = rssFeed.features[indexPath.row];
    cell.textLabel.text = rssItem.title;
    
    NSLog(@"makeCell:%@", NSStringFromCGRect(self.frame));
    NSLog(@"%@", NSStringFromCGRect(self.horizontalTableView.frame));
    
    NSLog(@"%@", NSStringFromCGRect(cell.frame));
    NSLog(@"%@", NSStringFromCGRect(cell.contentView.frame));
    
    tableView.delegate = self;

//    CGRect frame = cell.frame;
  //  cell.transform = CGAffineTransformMakeRotation(-M_PI/-2);
//    cell.frame = (CGRect){0, 0, 320,100};
////    cell.frame = (CGRect){0, 0, 100,320};
//    CGRect frame = cell.contentView.frame;
////    cell.contentView.transform = CGAffineTransformMakeRotation(-M_PI/-(2 + (indexPath.row/2)));
//   cell.contentView.transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(-160, -50),CGAffineTransformMakeRotation(-M_PI/-2));
////    cell.contentView.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(indexPath.row * (M_PI/4)), CGAffineTransformMakeTranslation(0, -200));
 //   cell.transform = CGAffineTransformMakeRotation(indexPath.row * (M_PI/4));
    cell.contentView.transform = CGAffineTransformMakeRotation(M_PI/2.0);
///    cell.contentView.transform = CGAffineTransformMakeRotation(indexPath.row * (M_PI/4));
//    cell.contentView.frame = (CGRect){0, 0, 320,100};
/////    cell.contentView.frame = (CGRect){0, 0, 100,320};
//    frame.size.width = 30;
//    cell.contentView.frame = frame;

//    NSLog(@"makeCell:%@", NSStringFromCGRect(self.frame));
//    NSLog(@"%@", NSStringFromCGRect(self.horizontalTableView.frame));

//    NSLog(@"%@", NSStringFromCGRect(cell.frame));
//    NSLog(@"%@", NSStringFromCGRect(cell.contentView.frame));

    //Since we are reusing the cells, old image view needs to be removed form the cell
    Boolean needsImage = true;
    Boolean needsText = true;
    for (UIView *view in cell.subviews)
    {
        if (view.tag == 7)
        {
            UIImageView *imgView = (UIImageView *)view;
            imgView.image = rssItem.appIcon;
            needsImage = false;
        }
        else if (view.tag == 6)
        {
            UILabel *lblView = (UILabel *)view;
            lblView.text = rssItem.title;
            needsText = false;
        }
//        [view removeFromSuperview];
    }
    
    if (needsImage)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(-50, 110, 320, 100)];
        imageView.image = rssItem.appIcon;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        CGAffineTransform rotateImage = CGAffineTransformMakeRotation(M_PI_2);
        imageView.transform = rotateImage;
        imageView.tag = 7;
        if (rssItem.appIcon == NULL)
        {
            [IconDownloader download:rssItem indexPath:indexPath delegate:self isItem:false];
        }
//        imageView.layer.masksToBounds = YES;
//        imageView.layer.cornerRadius = 5.0;
        [cell addSubview:imageView];
    }
    if (needsText)
    {
        UILabel *lblView = [[UILabel alloc] initWithFrame:CGRectMake(-50, 110, 200, 20)];
        lblView.text = rssItem.title;
        CGAffineTransform rotateImage = CGAffineTransformMakeRotation(M_PI_2);
        lblView.transform = rotateImage;
        lblView.tag = 6;
        [cell addSubview:lblView];
    }

    int maxFeatures = rssFeed.features.count;
    int newleftmost = leftMostFeature;
    if (leftMostFeature <= indexPath.row)
    {
        newleftmost = MAX(indexPath.row-1, 0);
        newleftmost = MIN(maxFeatures - 4, newleftmost);
    }
    else if (leftMostFeature >= indexPath.row)
    {
        newleftmost = MAX(indexPath.row-2, 0);
        newleftmost = MIN(maxFeatures - 4, newleftmost);
    }

    if (newleftmost != leftMostFeature)
    {
        leftMostFeature = newleftmost;
        if (self.imageView1 != NULL)
        {
            CRSSItem *rssItem1 = rssFeed.features[leftMostFeature];
            [imageView1 setImage:rssItem1.appIcon forState:UIControlStateNormal];
        }
        if (self.imageView2 != NULL)
        {
            CRSSItem *rssItem2 = rssFeed.features[leftMostFeature+1];
            [imageView2 setImage:rssItem2.appIcon forState:UIControlStateNormal];
        }
        if (self.imageView3 != NULL)
        {
            CRSSItem *rssItem3 = rssFeed.features[leftMostFeature+2];
            [imageView3 setImage:rssItem3.appIcon forState:UIControlStateNormal];
        }
        if (self.imageView4 != NULL)
        {
            CRSSItem *rssItem4 = rssFeed.features[leftMostFeature+3];
            [imageView4 setImage:rssItem4.appIcon forState:UIControlStateNormal];
        }
    }
    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        CRSSItem *object = rssFeed.features[indexPath.row];
        self.detailViewController.detailItem = object;
    }
}

- (IBAction)onFeature:(id)sender
{
    int index = leftMostFeature+[sender tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [horizontalTableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
    
    [scrollView scrollRectToVisible:CGRectMake(scrollView.frame.size.width*index, 0, scrollView.frame.size.width , scrollView.frame.size.height) animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.horizontalTableView indexPathForSelectedRow];
        CRSSItem *object = rssFeed.features[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
}

/*- (void)setFrame:(CGRect)frame
{
    CGRect oldFrame = self.horizontalTableView.frame;
    
    [super setFrame:frame];
//    [horizontalTableView setFrame:self.bounds];
    
//    self.transform = CGAffineTransformMakeRotation(-M_PI/2.0); // transform after setFrame

    
    NSLog(@"setFrame:%@", NSStringFromCGRect(self.horizontalTableView.frame));
    NSLog(@"oldFrame:%@", NSStringFromCGRect(oldFrame));
    NSLog(@"newFrame:%@", NSStringFromCGRect(frame));
    NSLog(@"%@", NSStringFromCGRect(self.bounds));
    
    self.horizontalTableView.frame = (CGRect){ 0, 0, frame.size.width, frame.size.height};
//    self.horizontalTableView.frame = (CGRect){ 0, 0, 100, 320};
 }*/

- (void)updateFeed
{
    // Update the view.
    [horizontalTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
//    [horizontalTableView reloadData];

    scrollView.contentSize =
    CGSizeMake(
               scrollView.frame.size.width * rssFeed.features.count,
               scrollView.frame.size.height);
	scrollView.contentOffset = CGPointMake(0, 0);
    
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
	}
	else
	{
		CGRect pageFrame = pageController.view.frame;
		pageFrame.origin.y = scrollView.frame.size.height;
		pageController.view.frame = pageFrame;
	}
    
	pageController.pageIndex = newIndex;
        
    int maxFeatures = rssFeed.features.count;
    int newleftmost = leftMostFeature;
    if (leftMostFeature <= newIndex)
    {
        newleftmost = MAX(newIndex-1, 0);
        newleftmost = MIN(maxFeatures - 4, newleftmost);
    }
    else if (leftMostFeature >= newIndex)
    {
        newleftmost = MAX(newIndex-2, 0);
        newleftmost = MIN(maxFeatures - 4, newleftmost);
    }
    if (newleftmost != leftMostFeature)
    {
        leftMostFeature = newleftmost;
        if (self.imageView1 != NULL)
        {
            CRSSItem *rssItem1 = rssFeed.features[leftMostFeature];
            [imageView1 setImage:rssItem1.appIcon forState:UIControlStateNormal];
        }
        if (self.imageView2 != NULL)
        {
            CRSSItem *rssItem2 = rssFeed.features[leftMostFeature+1];
            [imageView2 setImage:rssItem2.appIcon forState:UIControlStateNormal];
        }
        if (self.imageView3 != NULL)
        {
            CRSSItem *rssItem3 = rssFeed.features[leftMostFeature+2];
            [imageView3 setImage:rssItem3.appIcon forState:UIControlStateNormal];
        }
        if (self.imageView4 != NULL)
        {
            CRSSItem *rssItem4 = rssFeed.features[leftMostFeature+3];
            [imageView4 setImage:rssItem4.appIcon forState:UIControlStateNormal];
        }
    }

}


// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
    if ((iconDownloader != nil) && !iconDownloader.isItem)
    {
        UITableViewCell *cell = [self.horizontalTableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        
        // Display the newly loaded image
        UIImageView *imgView = (UIImageView *)[cell viewWithTag:2];
        imgView.image = iconDownloader.appRecord.appIcon;
        //        cell.imageView.image = iconDownloader.appRecord.appIcon;

        [IconDownloader removeDownload:iconDownloader.indexPathInTableView];
    }
    
    // Remove the IconDownloader from the in progress list.
    // This will result in it being deallocated.
//    [imageDownloadsInProgress removeObjectForKey:indexPath];
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
    
	[currentPage updateTextViews:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)newScrollView
{
	[self scrollViewDidEndScrollingAnimation:newScrollView];
}

@end
