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
        
        UITapGestureRecognizer *tapRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(tap:)];
        [self addGestureRecognizer:tapRecognizer];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 10.0);
    CGContextSetLineCap(context, kCGLineCapSquare);
    
    // Draw complete lines in black
    // [UIColor set] is used by drawing methods to set the color used by drawing methods
    // so you don't change the color for individual strokes, instead you change the color
    // and then put the drawing methods for that color after it
    [[UIColor blackColor] set];
    for (Line *line in completeLines) {
        CGContextMoveToPoint(context, [line begin].x, [line begin].y);
        CGContextAddLineToPoint(context, [line end].x, [line end].y);
        CGContextStrokePath(context);
    }
    
    // Draw lines in process in red
    [[UIColor redColor] set];
    for (NSValue *v in linesInProcess) {
        Line *line = [linesInProcess objectForKey:v];
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
    for (UITouch *t in touches) {
        
        // Is this a double tap?
        if ([t tapCount] > 1) {
            [self clearAll];
            return;
        }
        
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

@end


























