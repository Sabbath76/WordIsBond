//
//  ViewControllerAbout.m
//  WordIsBond
//
//  Created by Jose Lopes on 22/07/2014.
//  Copyright (c) 2014 Tom Berry. All rights reserved.
//

#import "ViewControllerAbout.h"

@interface ViewControllerAbout ()

@end

@implementation ViewControllerAbout

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
    
    self.screenName = @"About";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)onTom:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.linkedin.com/profile/view?id=24993502"]];
}

- (IBAction)onOmer:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.linkedin.com/profile/view?id=107869167"]];
}

- (IBAction)onJose:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.linkedin.com/profile/view?id=5826286"]];
}

@end
