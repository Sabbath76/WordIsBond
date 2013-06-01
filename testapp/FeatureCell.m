//
//  FeatureCell.m
//  testapp
//
//  Created by Jose Lopes on 21/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "FeatureCell.h"

@implementation FeatureCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
