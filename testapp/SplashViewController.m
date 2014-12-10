//
//  SplashViewController.m
//  WordIsBond
//
//  Created by Jose Lopes on 04/12/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "SplashViewController.h"
#import "RSSFeed.h"
#import "SelectedItem.h"


@interface SplashViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *m_loadingSpinner;

@end

@implementation SplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

        //--- Animate the loading spinner
        [self spinWithOptions:UIViewAnimationOptionCurveEaseIn];
       
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveNewRSSFeed:)
                                                     name:@"NewRSSFeed"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(failedNewRSSFeed:)
                                                     name:@"FailedFeed"
                                                   object:nil];
        RSSFeed *feed = [RSSFeed getInstance];
        [feed LoadFeed];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Custom initialization
    //--- Animate the loading spinner
    [self spinWithOptions:UIViewAnimationOptionCurveEaseIn];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNewRSSFeed:)
                                                 name:@"NewRSSFeed"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(failedNewRSSFeed:)
                                                 name:@"FailedFeed"
                                               object:nil];
    RSSFeed *feed = [RSSFeed getInstance];
    [feed LoadFeed];
}

- (void) spinWithOptions: (UIViewAnimationOptions) options {
    // this spin completes 360 degrees every 2 seconds
    [UIView animateWithDuration: 0.5f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         self.m_loadingSpinner.transform = CGAffineTransformRotate(self.m_loadingSpinner.transform, M_PI / 2);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                                  // if flag still set, keep spinning with constant speed
                                 [self spinWithOptions: UIViewAnimationOptionCurveLinear];
                        }
                     }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) failedNewRSSFeed:(NSNotification *) notification
{
}

- (void) receiveNewRSSFeed:(NSNotification *) notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self ];
//                                             selector:@selector(receiveNewRSSFeed:)
//                                                 name:@"NewRSSFeed"
//                                               object:nil];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [self dismissViewControllerAnimated:YES completion:^{}];

        RSSFeed *pFeed = [RSSFeed getInstance];
        if ((pFeed.features.count > 0) || (pFeed.items.count > 0))
        {
            SelectedItem *item = [SelectedItem alloc];
            item->isFavourite = false;
            if (pFeed.features.count > 0)
            {
                item->isFeature = true;
                item->item = pFeed.features[0];
            }
            else
            {
                item->isFeature = false;
                item->item = pFeed.items[0];
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:@"SetDetailItem" object:item];
        }
    }
    else
    {
        [self performSegueWithIdentifier: @"OpenMain" sender:self];
    }
}

@end
