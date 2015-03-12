//
//  ViewControllerTrackMenu.m
//  WordIsBond
//
//  Created by Jose Lopes on 07/03/2015.
//  Copyright (c) 2015 Tom Berry. All rights reserved.
//

#import "ViewControllerTrackMenu.h"
#import "SelectedItem.h"

#import <Social/Social.h>
#import <Accounts/Accounts.h>


@interface ViewControllerTrackMenu ()
{
    TrackInfo *curTrackInfo;
}
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnViewPost;
@property (weak, nonatomic) IBOutlet UIButton *btnBuyUrl;

@end

@implementation ViewControllerTrackMenu

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.lblTitle setText:curTrackInfo->title];
    
    [self.btnBuyUrl setHidden:(curTrackInfo->sourceUrl == nil)];
    
    [self.btnViewPost setImage:[curTrackInfo->pItem iconImage] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onTweet:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        CRSSItem *item = curTrackInfo->pItem;
        
        [mySLComposerSheet setInitialText:item.title];
        
        [mySLComposerSheet addImage:item.iconImage];
        
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
        CRSSItem *item = curTrackInfo->pItem;
        
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

- (IBAction)onBuyURL:(id)sender
{
    NSURL *url = [NSURL URLWithString:curTrackInfo->sourceUrl];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)onViewPost:(id)sender {
    
    SelectedItem *item = [SelectedItem alloc];
    item->isFavourite = false;
    item->isFeature = false;
    TrackInfo *track = curTrackInfo;
    item->item = track->pItem;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ViewPost" object:item];


    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onClose:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) setTrackItem:(TrackInfo *)trackInfo
{
    curTrackInfo = trackInfo;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end