//
//  ViewControllerMenu.m
//  testapp
//
//  Created by Jose Lopes on 04/10/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "ViewControllerMenu.h"
#import "RSSFeed.h"
#import "CRSSItem.h"
#import "UserData.h"
#import "SelectedItem.h"

#import "MasterViewController.h"
#import "DetailViewController.h"


@interface ViewControllerMenu ()
{
    bool shouldBeginEditing;
    bool showAudio;
    bool showVideo;
    bool showText;
    NSString *filter;
    __weak IBOutlet UITableView *tableFavourites;
    
    MasterViewController *masterViewController;
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
    
    [[UserData get] addListener:self];

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
  
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"CloseMenu"
     object:self];

    [tableFavourites setEditing:true];
//    [masterViewController setMenuOpen:false];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    [self updateFeedFilter];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return true;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[UserData get] favourites].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Favourite" forIndexPath:indexPath];
    NSArray *favouriteArray = [[[UserData get] favourites] allObjects];
    CRSSItem *item = [favouriteArray objectAtIndex:indexPath.row];
    cell.textLabel.text = item.title;
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        //add code here for when you hit delete
        NSMutableSet *favouriteSet = [[UserData get] favourites];
        NSArray *favouriteArray = [favouriteSet allObjects];
        [favouriteSet removeObject:[favouriteArray objectAtIndex:indexPath.row]];
        [tableFavourites deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//        [[self delegate]didDeletedBillItemRow:row];
//        [tableFavourites deleteRO];
    }
}

- (void)onFavouritesChanged
{
    [tableFavourites reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *favouriteArray = [[[UserData get] favourites] allObjects];
    CRSSItem *item = [favouriteArray objectAtIndex:indexPath.row];
    SelectedItem *selItem = [SelectedItem alloc];
    selItem->isFavourite = true;
    selItem->item = item;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ViewPost" object:selItem];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetailFavourite"])
    {
        NSIndexPath *indexPath = [tableFavourites indexPathForSelectedRow];
        NSArray *favouriteArray = [[[UserData get] favourites] allObjects];
        CRSSItem *item = [favouriteArray objectAtIndex:indexPath.row];
        [[segue destinationViewController] setDetailItem:item];
    }

}

@end
