//
//  DetailViewController.m
//  testapp
//
//  Created by Jose Lopes on 30/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "DetailViewController.h"
#import "UserData.h"


@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
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
            [_webView loadHTMLString:[self.detailItem description] baseURL:nil];
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
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_banner_logo"]];

    [self configureView];
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
            [_webView loadHTMLString:[self.detailItem description] baseURL:nil];
        }
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

@end
