//
//  FeatureCell.h
//  testapp
//
//  Created by Jose Lopes on 21/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSSFeed.h"
#import "IconDownloader.h"

@class DetailViewController;
@class FeatureController;

@interface FeatureCell : UITableViewCell <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, IconDownloaderDelegate>
{
    int leftMostFeature;
	
	FeatureController *currentPage;
	FeatureController *nextPage;
}

@property (nonatomic, retain) IBOutlet UITableView *horizontalTableView;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIButton *imageView1;
@property (nonatomic, retain) IBOutlet UIButton *imageView2;
@property (nonatomic, retain) IBOutlet UIButton *imageView3;
@property (nonatomic, retain) IBOutlet UIButton *imageView4;
@property (nonatomic, retain) RSSFeed *rssFeed;
@property (strong, nonatomic) DetailViewController *detailViewController;

- (void)updateFeed;
- (IBAction)onFeature:(id)sender;

@end
