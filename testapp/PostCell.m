//
//  PostCell.m
//  WordIsBond
//
//  Created by Jose Lopes on 02/02/2014.
//  Copyright (c) 2014 Tom Berry. All rights reserved.
//

#import "PostCell.h"

@interface PostCell ()

//@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
//@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
//@property (nonatomic, weak) IBOutlet UIImageView *timeImageView;



@property (nonatomic, weak) IBOutlet UILabel *title; // 1
@property (nonatomic, weak) IBOutlet UILabel *date;  // 5
@property (nonatomic, weak) IBOutlet UIButton *miniImage; // 4
@property (nonatomic, weak) IBOutlet UIImageView *postTypeImage; //3
@property (nonatomic, weak) IBOutlet UIImageView *blurredImage; // 2
@property (nonatomic, weak) IBOutlet UIView *animateView; // 8
@property (nonatomic, weak) IBOutlet UIImageView *fullImage; // 9
@property (nonatomic, weak) IBOutlet UIToolbar *options; // 6

@end

@implementation PostCell
{
    CALayer *m_maskingLayer;
}
/*
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        if (self.miniImage)
        {
            CALayer *_maskingLayer = [CALayer layer];
            _maskingLayer.frame = self.miniImage.bounds;
            UIImage *stretchableImage = (id)[UIImage imageNamed:@"cornerfull"];
            
            _maskingLayer.contents = (id)stretchableImage.CGImage;
            _maskingLayer.contentsScale = [UIScreen mainScreen].scale; //<-needed for the retina display, otherwise our image will not be scaled properly
            _maskingLayer.contentsCenter = CGRectMake(15.0/stretchableImage.size.width,15.0/stretchableImage.size.height,5.0/stretchableImage.size.width,5.0f/stretchableImage.size.height);
            
            [self.miniImage.layer setMask:_maskingLayer];
        }

    }
    return self;
}
*/
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setupIfNeeded
{
/*  //--- Masking layer disabled
    if (self.miniImage && (m_maskingLayer == nil))
    {
        CALayer *_maskingLayer = [CALayer layer];
        _maskingLayer.frame = self.miniImage.bounds;
        UIImage *stretchableImage = (id)[UIImage imageNamed:@"cornerfull"];
        
        _maskingLayer.contents = (id)stretchableImage.CGImage;
        _maskingLayer.contentsScale = [UIScreen mainScreen].scale; //<-needed for the retina display, otherwise our image will not be scaled properly
        _maskingLayer.contentsCenter = CGRectMake(15.0/stretchableImage.size.width,15.0/stretchableImage.size.height,5.0/stretchableImage.size.width,5.0f/stretchableImage.size.height);
        
        [self.miniImage.layer setMask:_maskingLayer];
        m_maskingLayer = _maskingLayer;
    }*/
}

@end
