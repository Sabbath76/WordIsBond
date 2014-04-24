//
//  PostCell.h
//  WordIsBond
//
//  Created by Jose Lopes on 02/02/2014.
//  Copyright (c) 2014 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostCell : UITableViewCell

@property (nonatomic, weak, readonly) UILabel *title;
@property (nonatomic, weak, readonly) UILabel *date;
@property (nonatomic, weak, readonly) UIButton *expandButton;
@property (nonatomic, weak, readonly) UIImageView *miniImage;
@property (nonatomic, weak, readonly) UIImageView *postTypeImage;
@property (nonatomic, weak, readonly) UIImageView *blurredImage;
@property (nonatomic, weak, readonly) UIView *animateView;
@property (nonatomic, weak, readonly) UIImageView *fullImage;
@property (nonatomic, weak, readonly) UIToolbar *options;

- (void) setupIfNeeded;

@end
