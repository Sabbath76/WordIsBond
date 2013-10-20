//
//  ViewControllerMenu.h
//  testapp
//
//  Created by Jose Lopes on 04/10/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserData.h"

@interface ViewControllerMenu : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, FavouritesChangedDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *filterAudio;
@property (weak, nonatomic) IBOutlet UISwitch *filterVideo;
@property (weak, nonatomic) IBOutlet UISwitch *filterText;

@end
