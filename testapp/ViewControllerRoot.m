//
//  ViewControllerRoot.m
//  testapp
//
//  Created by Jose Lopes on 05/09/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "ViewControllerRoot.h"
#import "ViewControllerMediaPlayer.h"

@interface ViewControllerRoot ()

@end

@implementation ViewControllerRoot
{
    __weak IBOutlet NSLayoutConstraint *mediaPlayerPosition;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"mediaplayer_embed"])
    {
        ViewControllerMediaPlayer * childViewController = (ViewControllerMediaPlayer *) [segue destinationViewController];
        // do something with the AlertView's subviews here...
        [childViewController setSlideConstraint:mediaPlayerPosition];
    }
}
@end
