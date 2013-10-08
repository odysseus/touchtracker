//
//  TouchDrawView.h
//  TouchTracker
//
//  Created by Ryan Case on 10/5/13.
//  Copyright (c) 2013 Ryan Case. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Line;

@interface TouchDrawView : UIView
{
    NSMutableDictionary *linesInProcess;
    NSMutableArray *completeLines;
}

@property (nonatomic, weak) Line *selectedLine;

- (void)clearAll;
- (void)endTouches:(NSSet *)touches;
- (void)tap:(UIGestureRecognizer *)gr;
- (Line *)lineAtPoint:(CGPoint)point;
- (void)deleteLine:(id)sender;

@end
