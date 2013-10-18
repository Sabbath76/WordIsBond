//
//  ViewControllerMediaPlayer.h
//  testapp
//
//  Created by Jose Lopes on 05/09/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIToolbarDragger.h"
#import <AVFoundation/AVFoundation.h>
#import "IconDownloader.h"


@interface ViewControllerMediaPlayer : UIViewController <AVAudioPlayerDelegate, IconDownloaderDelegate>

@property (weak, nonatomic) IBOutlet UIToolbarDragger *toolbarDragger;
@property (weak, nonatomic) IBOutlet UIImageView *currentImage;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UIView *bar;

@end
