//
//  ItemCell.h
//  testapp
//
//  Created by Jose Lopes on 01/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ItemCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *title;
//@property (nonatomic, weak) IBOutlet UILabel *prepTimeLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIImageView *typeIcon;

@end
