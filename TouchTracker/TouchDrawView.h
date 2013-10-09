//
//  TouchDrawView.h
//  TouchTracker
//
//  Created by Ryan Case on 10/5/13.
//  Copyright (c) 2013 Ryan Case. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Line;

@interface TouchDrawView : UIView <UIGestureRecognizerDelegate>
{
    NSMutableDictionary *linesInProcess;
    NSMutableArray *completeLines;
    
    UIPanGestureRecognizer *moveRecognizer;
    UISegmentedControl *segmentedControl;
}

@property (nonatomic, weak) Line *selectedLine;
@property (nonatomic) UIColor *selectedColor;

- (void)clearAll;
- (void)endTouches:(NSSet *)touches;
- (Line *)lineAtPoint:(CGPoint)point;
- (void)deleteLine:(id)sender;

// Gesture Methods
- (void)longPress:(UIGestureRecognizer *)gr;
- (void)tap:(UIGestureRecognizer *)gr;
- (void)threeFingerSwipeUp:(UIGestureRecognizer *)gr;
- (void)threeFingerSwipeDown:(UIGestureRecognizer *)gr;
- (void)changeColor:(UISegmentedControl *)sender;

- (int)numberOfLines;

@end
