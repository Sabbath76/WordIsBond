//
//  ViewControllerMediaPlayer.h
//  testapp
//
//  Created by Jose Lopes on 05/09/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIToolbarDragger.h"


@interface ViewControllerMediaPlayer : UIViewController

@property (weak, nonatomic) IBOutlet UIToolbarDragger *toolbarDragger;
@property (weak, nonatomic) IBOutlet UIImageView *currentImage;

@end
