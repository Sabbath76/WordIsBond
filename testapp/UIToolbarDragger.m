//
//  UIToolbarDragger.m
//  testapp
//
//  Created by Jose Lopes on 03/09/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "UIToolbarDragger.h"

@implementation UIToolbarDragger
{
    int bottomOffset;
    int midOffset;
}

@synthesize owningView;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self->bottomOffset = 40;
        self->midOffset = 120;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        self->bottomOffset = 40;
        self->midOffset = 120;
    }
    return self;
  
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    UIView *moveView = self.superview.superview;
    if (moveView)
    {
        UITouch *aTouch = [touches anyObject];
        CGPoint prevLocation = [aTouch previousLocationInView:moveView.superview];
        CGPoint location = [aTouch locationInView:moveView.superview];
        
        CGRect parentFrame = moveView.superview.frame;
        
        prevLocation.y = MAX(prevLocation.y, 0);
        prevLocation.y = MIN(prevLocation.y, parentFrame.size.height - bottomOffset);
        
        location.y = MAX(location.y, 0);
        location.y = MIN(location.y, parentFrame.size.height - bottomOffset);
        
        [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
        moveView.frame = CGRectMake(moveView.frame.origin.x, moveView.frame.origin.y + location.y - prevLocation.y,
                                moveView.frame.size.width, moveView.frame.size.height);
        [UIView commitAnimations];
//        [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
//        self.frame = CGRectMake(self.frame.origin.x, location.y,
//                                self.frame.size.width, self.frame.size.height);
//        [UIView commitAnimations];
    }
   
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    UIView *moveView = self.superview.superview;
    if (moveView)
    {
        CGRect parentFrame = moveView.superview.frame;

        if (moveView.frame.origin.y < (parentFrame.origin.y + (parentFrame.size.height / 2)))
        {
            [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
            moveView.frame = CGRectMake(moveView.frame.origin.x, 0,
                                        moveView.frame.size.width, moveView.frame.size.height);
            [UIView commitAnimations];
            
        }
        else if (moveView.frame.origin.y < (parentFrame.origin.y + (parentFrame.size.height * 0.75)))
        {
            [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
            moveView.frame = CGRectMake(moveView.frame.origin.x, parentFrame.size.height - midOffset,
                                        moveView.frame.size.width, moveView.frame.size.height);
            [UIView commitAnimations];
        }
        else
        {
            [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
            moveView.frame = CGRectMake(moveView.frame.origin.x, parentFrame.size.height - bottomOffset,
                                        moveView.frame.size.width, moveView.frame.size.height);
            [UIView commitAnimations];            
        }
    }
}


@end
