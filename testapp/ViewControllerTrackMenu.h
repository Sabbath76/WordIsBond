//
//  ViewControllerTrackMenu.h
//  WordIsBond
//
//  Created by Jose Lopes on 07/03/2015.
//  Copyright (c) 2015 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackInfo.h"
#import "GAITrackedViewController.h"

@interface ViewControllerTrackMenu : GAITrackedViewController

- (void) setTrackItem:(TrackInfo *)trackInfo;

@end
