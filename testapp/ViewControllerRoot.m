//
//  ViewControllerRoot.m
//  testapp
//
//  Created by Jose Lopes on 05/09/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "ViewControllerRoot.h"
#import "ViewControllerMediaPlayer.h"

@interface ViewControllerRoot ()

@end

@implementation ViewControllerRoot
{
    __weak IBOutlet NSLayoutConstraint *mediaPlayerPosition;
    __weak IBOutlet UIView *m_mainView;
    float m_slideInitialPos;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"mediaplayer_embed"])
    {
        ViewControllerMediaPlayer * childViewController = (ViewControllerMediaPlayer *) [segue destinationViewController];
        // do something with the AlertView's subviews here...
        [childViewController setSlideConstraint:mediaPlayerPosition];
    }
}


float MENU_ANIMATION_DURATION = 0.4f;
float MENU_FAST_ANIMATION_DURATION = 0.1f;

- (void) setMenuOpen:(bool)state
{
    CGRect destination = m_mainView.frame;
    
    if (state)
    {
        destination.origin.x = 270;
        
        [m_mainView setUserInteractionEnabled:false];
    }
    else
    {
        destination.origin.x = 0;
        
        [m_mainView setUserInteractionEnabled:true];
    }
    
    [UIView beginAnimations:@"Bringing up menu" context:nil];
    m_mainView.frame = destination;
    [UIView commitAnimations];
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([m_mainView isUserInteractionEnabled])
    {
        return NO;
    }
    else if ([touch locationInView:m_mainView].x < 0)//(touch.view != m_mainView)
    {
        return NO;
    }
    
    return YES;
}

- (IBAction)onDrag:(UIPanGestureRecognizer *)sender
{
    UIView *dragView = m_mainView;
    
    float vX = 0.0;
    float compare;
    
    float min = 0.0f;
    float max = 270.0f;
    float threshold = (min+max)/2.0;
    
    switch (sender.state)
    {
        case UIGestureRecognizerStateBegan:
            m_slideInitialPos = dragView.frame.origin.x;
            break;
        case UIGestureRecognizerStateEnded:
        {
            vX = dragView.frame.origin.x + (MENU_ANIMATION_DURATION/2.0)*[sender velocityInView:self.view].x;
            compare = vX;
            bool closed = (compare < threshold);
            if (closed)
            {
                vX = min;
            }
            else
            {
                vX = max;
            }
            
            CGRect frame = dragView.frame;
            frame.origin.x = vX;
            [UIView animateWithDuration:MENU_ANIMATION_DURATION animations:^
             {
                 [dragView setFrame:frame];
             } completion:^(BOOL finished)
             {
                 [dragView setUserInteractionEnabled:closed];
                 if (closed)
                 {
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateMenuState"  object:self];
                 }
             }];
            
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            compare = m_slideInitialPos+[sender translationInView:self.view].x;
            compare = MAX(compare, min);
            compare = MIN(compare, max);
            
            CGRect frame = dragView.frame;
            frame.origin.x = compare;
            
            [UIView animateWithDuration:MENU_FAST_ANIMATION_DURATION animations:^{[dragView setFrame:frame];}];
            break;
        }
            
        default:
            break;
    }
}

- (IBAction)onTapDragView:(id)sender
{
    [self setMenuOpen:false];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateMenuState"  object:self];
}

@end
