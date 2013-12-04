//
//  DetailViewController.h
//  testapp
//
//  Created by Jose Lopes on 30/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CRSSItem.h"


@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, PostRequestDelegate, UIScrollViewDelegate, IconDownloaderDelegate, UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) id detailItem;
//@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnFavourite;

- (void)setDetailItem:(id)newDetailItem list:(NSArray *)sourceList;

@end
