//
//  UIWIBToolbar.m
//  testapp
//
//  Created by Jose Lopes on 03/09/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "UIWIBToolbar.h"

@implementation UIWIBToolbar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIButton *EmailBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
        [EmailBtn setBackgroundImage:[UIImage imageNamed:@"cutaway.png"] forState:UIControlStateNormal];
        EmailBtn.showsTouchWhenHighlighted = YES;
        
        UIBarButtonItem *EmailBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:EmailBtn];
        NSArray *buttons = [NSArray arrayWithObjects: EmailBarButtonItem, nil];
        [self setItems: buttons animated:NO];
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
    UIButton *EmailBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
    [EmailBtn setBackgroundImage:[UIImage imageNamed:@"cutaway.png"] forState:UIControlStateNormal];
    EmailBtn.showsTouchWhenHighlighted = YES;
    
    UIBarButtonItem *EmailBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:EmailBtn];
    NSArray *buttons = [NSArray arrayWithObjects: EmailBarButtonItem, nil];
    [self setItems: buttons animated:NO];
    
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
//    CGRect trimRect = rect;
//    trimRect.size.height /= 2;
//    trimRect.origin.y += trimRect.size.height;
//    [super drawRect:trimRect];//]drawRect:rect];
       [super drawRect:rect];
}


@end
