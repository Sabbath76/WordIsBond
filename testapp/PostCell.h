//
//  PostCell.h
//  WordIsBond
//
//  Created by Jose Lopes on 02/02/2014.
//  Copyright (c) 2014 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostCell : UITableViewCell

@property (nonatomic, weak, readonly) UILabel *title; // 1
@property (nonatomic, weak, readonly) UILabel *date;  // 5
@property (nonatomic, weak, readonly) UIImageView *miniImage; // 4
@property (nonatomic, weak, readonly) UIImageView *postTypeImage; //3
@property (nonatomic, weak, readonly) UIImageView *blurredImage; // 2
@property (nonatomic, weak, readonly) UIView *animateView; // 8
@property (nonatomic, weak, readonly) UIImageView *fullImage; // 9
@property (nonatomic, weak, readonly) UIToolbar *options; // 9

- (void) setupIfNeeded;

@end
