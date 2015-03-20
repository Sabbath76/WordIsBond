//
//  ViewControllerTrackMenu.m
//  WordIsBond
//
//  Created by Jose Lopes on 07/03/2015.
//  Copyright (c) 2015 Tom Berry. All rights reserved.
//

#import "ViewControllerTrackMenu.h"
#import "SelectedItem.h"
#import "UserData.h"

#import <Social/Social.h>
#import <Accounts/Accounts.h>


@interface ViewControllerTrackMenu ()
{
    TrackInfo *curTrackInfo;
}
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnViewPost;
@property (weak, nonatomic) IBOutlet UIButton *btnBuyUrl;
@property (weak, nonatomic) IBOutlet UIButton *btnFavourite;

@end

@implementation ViewControllerTrackMenu

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    CRSSItem *item = curTrackInfo->pItem;

    [self.lblTitle setText:curTrackInfo->title];
    
    if (curTrackInfo->sourceUrl != nil)
    {
        if ([curTrackInfo->pItem audioHost] == Bandcamp)
        {
            [self.btnBuyUrl setImage:[UIImage imageNamed:@"bandcamp_black"] forState:UIControlStateNormal];
        }
        else if ([curTrackInfo->pItem audioHost] == Soundcloud)
        {
            [self.btnBuyUrl setImage:[UIImage imageNamed:@"soundcloud"] forState:UIControlStateNormal];
        }
    }
    [self.btnBuyUrl setHidden:(curTrackInfo->sourceUrl == nil)];
    
    [self.btnViewPost setImage:[item iconImage] forState:UIControlStateNormal];
    
    NSMutableSet *favourites = [[UserData get] favourites];
    UIImage *image = [[UIImage imageNamed:@"icon_favourite_off"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.btnFavourite setImage:image forState:UIControlStateNormal];
    if ([favourites containsObject:item])
    {
        self.btnFavourite.tintColor = [UIColor wibColour];
    }
    else
    {
        self.btnFavourite.tintColor = [UIColor whiteColor];
    }

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

- (IBAction)onFavourite:(id)sender
{
    NSMutableSet *favourites = [[UserData get] favourites];
    CRSSItem *item = curTrackInfo->pItem;
    if ([favourites containsObject:item])
    {
        self.btnFavourite.tintColor = [UIColor whiteColor];
        [favourites removeObject:item];
    }
    else
    {
        self.btnFavourite.tintColor = [UIColor wibColour];
        [favourites addObject:item];
    }
    [[UserData get] onChanged];

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
