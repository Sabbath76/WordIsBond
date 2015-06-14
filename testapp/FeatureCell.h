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

@interface FeatureCell : UITableViewCell <UIScrollViewDelegate, IconDownloaderDelegate>
{
    NSInteger leftMostFeature;
	
	FeatureController *currentPage;
	FeatureController *nextPage;
}

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIButton *imageView1;
@property (nonatomic, weak) IBOutlet UIButton *imageView2;
@property (nonatomic, weak) IBOutlet UIButton *imageView3;
@property (nonatomic, weak) IBOutlet UIButton *imageView4;
@property (weak, nonatomic) IBOutlet UIButton *imageView5;
@property (nonatomic, weak) RSSFeed *rssFeed;

- (void)updateFeed;
- (IBAction)onFeature:(id)sender;
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;

@end
