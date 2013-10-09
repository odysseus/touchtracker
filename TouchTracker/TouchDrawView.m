//
//  TouchDrawView.m
//  TouchTracker
//
//  Created by Ryan Case on 10/5/13.
//  Copyright (c) 2013 Ryan Case. All rights reserved.
//

#import "TouchDrawView.h"
#import "Line.h"

@implementation TouchDrawView

@synthesize selectedLine;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Instantiate the instance variables
        linesInProcess = [[NSMutableDictionary alloc] init];
        completeLines = [[NSMutableArray alloc] init];
        
        [self setBackgroundColor:[UIColor whiteColor]];
        
        [self setMultipleTouchEnabled:YES];
        
        // Adding a tap gesture recognizer
        UITapGestureRecognizer *singleTapRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(tap:)];
        [singleTapRecognizer setNumberOfTapsRequired:1];
        [self addGestureRecognizer:singleTapRecognizer];
        
        // Adding a double tap gesture recognizer
        UITapGestureRecognizer *doubleTapRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(clearAll)];
        [doubleTapRecognizer setNumberOfTapsRequired:2];
        [self addGestureRecognizer:doubleTapRecognizer];
        
        // Adding a long press recognizer
        UILongPressGestureRecognizer *pressRecognizer =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(longPress:)];
        [self addGestureRecognizer:pressRecognizer];
        
        // Adding a pan gesture recognizer
        moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                 action:@selector(moveLine:)];
        [moveRecognizer setDelegate:self];
        [moveRecognizer setCancelsTouchesInView:NO];
        [self addGestureRecognizer:moveRecognizer];
        
        // Adding an upwards three finger swipe gesture
        UISwipeGestureRecognizer *threeFingerSwipeUp =
        [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(threeFingerSwipeUp:)];
        [threeFingerSwipeUp setNumberOfTouchesRequired:3];
        [threeFingerSwipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
        [self addGestureRecognizer:threeFingerSwipeUp];
        
        // And a downwards three finger swipe
        UISwipeGestureRecognizer *threeFingerSwipeDown =
        [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(threeFingerSwipeDown:)];
        [threeFingerSwipeDown setNumberOfTouchesRequired:3];
        [threeFingerSwipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
        [self addGestureRecognizer:threeFingerSwipeDown];
        
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapSquare);
    // Fetch the velocity for variable line width
    CGPoint velocity = [moveRecognizer velocityInView:self];
    
    for (Line *line in completeLines) {
        // Because the background switches colors, we need to check for lines that have no
        // color assignment, and lines whose color is the same as the background
        if(![line lineColor] || ([line lineColor] == [self backgroundColor])) {
            // Then set them to the opposite of the background color
            if ([self backgroundColor] == [UIColor whiteColor]) {
                [line setLineColor:[UIColor blackColor]];
            } else {
                [line setLineColor:[UIColor whiteColor]];
            }
        }
        // Finally, set the line color and draw the line
        [[line lineColor] set];
        CGContextSetLineWidth(context, [line lineWidth]);
        CGContextMoveToPoint(context, [line begin].x, [line begin].y);
        CGContextAddLineToPoint(context, [line end].x, [line end].y);
        CGContextStrokePath(context);
    }
    
    // Draw lines in process in red
    [[UIColor redColor] set];
    for (NSValue *v in linesInProcess) {
        Line *line = [linesInProcess objectForKey:v];
        // Velocity has an x and y component, so velocity factor takes the absolute value
        // of the x and y components, adds them together and multiplies by 0.1 to keep it
        // mostly in the 0-100 range
        float velocityFactor = (fabsf(velocity.x) + fabsf(velocity.y)) * 0.1;
        // Originally set the line width with the velocityFactor directly, but that proved
        // wildly variable, so now it's set by conditional switch based on the velocityFactor
        if (velocityFactor < 25.0) {
            [line setLineWidth:5.0];
        } else if (velocityFactor >= 25.0 && velocityFactor < 50.0) {
            [line setLineWidth:10.0];
        } else if (velocityFactor >= 50.0 && velocityFactor < 100.0) {
            [line setLineWidth:15.0];
        } else if (velocityFactor > 100.0) {
            [line setLineWidth:20.0];
        }
        CGContextSetLineWidth(context, [line lineWidth]);
        CGContextMoveToPoint(context, [line begin].x, [line begin].y);
        CGContextAddLineToPoint(context, [line end].x, [line end].y);
        CGContextStrokePath(context);
    }
    
    // If there is a selected line, draw it
    if ([self selectedLine]) {
        [[UIColor greenColor] set];
        CGContextMoveToPoint(context, [[self selectedLine] begin].x,
                             [[self selectedLine] begin].y);
        CGContextAddLineToPoint(context, [[self selectedLine] end].x,
                                [[self selectedLine] end].y);
        CGContextStrokePath(context);
    }
}

- (void)clearAll
{
    // Clear both collections
    [linesInProcess removeAllObjects];
    [completeLines removeAllObjects];
    // And redraw the screen
    [self setNeedsDisplay];
}

// Touch Methods

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    // Reset the menu and selected lines in case one was selected when
    // the user began to draw
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    [self setSelectedLine:nil];
    
    for (UITouch *t in touches) {
        
        // Use the touch object (packed in an NSValue) as the key
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        
        // Create a line for the value
        CGPoint loc = [t locationInView:self];
        Line *newLine = [[Line alloc] init];
        [newLine setBegin:loc];
        [newLine setEnd:loc];
        
        // Put pair in dictionary
        [linesInProcess setObject:newLine forKey:key];
    }
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    // Update linesInProcess with moved touches
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        
        // Find the line for this touch
        Line *line = [linesInProcess objectForKey:key];
        
        // Update the line
        CGPoint loc = [t locationInView:self];
        [line setEnd:loc];
    }
    // Redraw
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    [self endTouches:touches];
}

- (void)touchesCancelled:(NSSet *)touches
               withEvent:(UIEvent *)event
{
    [self endTouches:touches];
}

- (void)endTouches:(NSSet *)touches
{
    // Remove ending touches from dictionary
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        Line *line = [linesInProcess objectForKey:key];
        
        // If this is a double tap, 'line' will be nil,
        // so make sure not to add it to the array
        if (line) {
            [completeLines addObject:line];
            [linesInProcess removeObjectForKey:key];
        }
    }
    // Redraw
    [self setNeedsDisplay];
}

- (void)tap:(UIGestureRecognizer *)gr
{
    NSLog(@"Tap");
    
    CGPoint point = [gr locationInView:self];
    [self setSelectedLine:[self lineAtPoint:point]];
    
    // Remove all lines in process so that a tap doesn't result
    // in a dot being drawn on the screen, then redraw
    [linesInProcess removeAllObjects];
    
    if ([self selectedLine]) {
        [self becomeFirstResponder];
        // Menu Controller is a singleton, so grab the shared instance
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        // Create an item for the menu bar
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete"
                                                            action:@selector(deleteLine:)];
        // Set the menu controller items (needs to be in an array)
        [menuController setMenuItems:[NSArray arrayWithObject:deleteItem]];
        // Tell the menu where to appear
        [menuController setTargetRect:CGRectMake(point.x, point.y, 2, 2) inView:self];
        // Now show it
        [menuController setMenuVisible:YES animated:YES];
    } else {
        // Hide the menu if no line is selected
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    [self setNeedsDisplay];
}

- (Line *)lineAtPoint:(CGPoint)p
{
    // Find a line close to p
    for (Line *l in completeLines) {
        CGPoint start = [l begin];
        CGPoint end = [l end];
        
        // Check a few points on the line
        for (float t = 0.0; t <= 1.0; t += 0.05) {
            float x = start.x + t * (end.x - start.x);
            float y = start.y + t * (end.y - start.y);
            
            // If the tapped point is within 20 points, let's return this line
            if (hypot(x - p.x, y - p.y) < 20.0) {
                return l;
            }
        }
    }
    // If nothing is close enough to the tapped point, then we didn't select a line
    return nil;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)deleteLine:(id)sender
{
    // Remove the selected line
    [completeLines removeObject:[self selectedLine]];
    // Redraw the display
    [self setNeedsDisplay];
}

- (void)longPress:(UIGestureRecognizer *)gr
{
    if ([gr state] == UIGestureRecognizerStateBegan) {
        CGPoint point = [gr locationInView:self];
        [self setSelectedLine:[self lineAtPoint:point]];
        if ([self selectedLine]) {
            [linesInProcess removeAllObjects];
        }
    } else if ([gr state] == UIGestureRecognizerStateEnded) {
        [self setSelectedLine:nil];
    }
    [self setNeedsDisplay];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
    (UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == moveRecognizer) {
        return YES;
    }
    return NO;
}

- (void)moveLine:(UIPanGestureRecognizer *)gr
{
    // If there's no line selected, do nothing
    if (![self selectedLine])
        return;
    
    // When the pan recognizer changes its position...
    if ([gr state] == UIGestureRecognizerStateChanged) {
        // How far has the pan moved?
        CGPoint translation = [gr translationInView:self];
        
        // Modify the current line with the new begin and end points
        CGPoint begin = [[self selectedLine] begin];
        CGPoint end = [[self selectedLine] end];
        begin.x += translation.x;
        begin.y += translation.y;
        end.x += translation.x;
        end.y += translation.y;
        
        // Finally set the new begin and end points
        [[self selectedLine] setBegin:begin];
        [[self selectedLine] setEnd:end];
        
        // And redraw the screen
        [self setNeedsDisplay];
        
        // Set the translation point to zero so the line doesn't fly
        // off the screen when moving because of math/translation issues
        [gr setTranslation:CGPointZero inView:self];
    }
}

- (void)threeFingerSwipeUp:(UIGestureRecognizer *)gr
{
    [linesInProcess removeAllObjects];
    
    // Change the first available color based on the background color
    if ([self backgroundColor] == [UIColor whiteColor]) {
        NSArray *rgbbArray = [[NSArray alloc] initWithObjects:@"Black", @"Red", @"Yellow", @"Blue", nil];
        segmentedControl = [[UISegmentedControl alloc] initWithItems:rgbbArray];
    } else {
        NSArray *rgbbArray = [[NSArray alloc] initWithObjects:@"White", @"Red", @"Yellow", @"Blue", nil];
        segmentedControl = [[UISegmentedControl alloc] initWithItems:rgbbArray];
    }
    
    // Choose where to present the segmented controller, attach an action and present it
    [segmentedControl setCenter:CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2)];
    [segmentedControl addTarget:nil
                         action:@selector(changeColor:)
               forControlEvents:UIControlEventValueChanged];
    [self addSubview:segmentedControl];
}

- (void)threeFingerSwipeDown:(UIGestureRecognizer *)gr
{
    [linesInProcess removeAllObjects];
    [segmentedControl removeFromSuperview];
}


- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if ( event.subtype == UIEventSubtypeMotionShake ) {
        [self flipBackground];
    }
    if ( [super respondsToSelector:@selector(motionEnded:withEvent:)] ) {
        [super motionEnded:motion withEvent:event];
    }
}

- (void)changeColor:(UISegmentedControl *)sender
{
    if ([self backgroundColor] == [UIColor whiteColor]) {
        NSArray *colorArray = [NSArray arrayWithObjects:[UIColor blackColor], [UIColor redColor], [UIColor yellowColor], [UIColor blueColor], nil];
        [self setSelectedColor:[colorArray objectAtIndex:[sender selectedSegmentIndex]]];
    } else {
        NSArray *colorArray = [NSArray arrayWithObjects:[UIColor whiteColor], [UIColor redColor], [UIColor yellowColor], [UIColor blueColor], nil];
        [self setSelectedColor:[colorArray objectAtIndex:[sender selectedSegmentIndex]]];
    }
}

- (void)flipBackground
{
    if ([self backgroundColor] == [UIColor whiteColor]) {
        [self setBackgroundColor:[UIColor blackColor]];
    } else {
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    [self setNeedsDisplay];
}
@end


























