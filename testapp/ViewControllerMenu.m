//
//  ViewControllerMenu.m
//  testapp
//
//  Created by Jose Lopes on 04/10/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "ViewControllerMenu.h"
#import "RSSFeed.h"

@interface ViewControllerMenu ()
{
    bool shouldBeginEditing;
    bool showAudio;
    bool showVideo;
    bool showText;
    NSString *filter;
}

@end

@implementation ViewControllerMenu

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
    
    shouldBeginEditing = true;
    showAudio = true;
    showVideo = true;
    showText = true;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateFeedFilter
{
    showAudio = [_filterAudio isOn];
    showVideo = [_filterVideo isOn];
    showText  = [_filterText isOn];
    
    [[RSSFeed getInstance] Filter:filter showAudio:showAudio showVideo:showVideo showText:showText];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"NewRSSFeed"
     object:self];
}

- (IBAction)updateFilter:(id)sender
{
    [self updateFeedFilter];
}

- (void)searchBar:(UISearchBar *)bar textDidChange:(NSString *)searchText {
    NSLog(@"searchBar:textDidChange: isFirstResponder: %i", [bar isFirstResponder]);
    if(![bar isFirstResponder])
    {
        // user tapped the 'clear' button
        shouldBeginEditing = NO;
        [self updateFeedFilter];
    }
}


- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
    // reset the shouldBeginEditing BOOL ivar to YES, but first take its value and use it to return it from the method call
    BOOL boolToReturn = shouldBeginEditing;
    shouldBeginEditing = YES;
    return boolToReturn;
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];

    showAudio = [_filterAudio isOn];
    showVideo = [_filterVideo isOn];
    showText  = [_filterText isOn];
    
    [[RSSFeed getInstance] FilterJSON:searchBar.text showAudio:showAudio showVideo:showVideo showText:showText];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    [self updateFeedFilter];
}


@end
