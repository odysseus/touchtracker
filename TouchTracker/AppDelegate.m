//
//  AppDelegate.m
//  TouchTracker
//
//  Created by Ryan Case on 10/4/13.
//  Copyright (c) 2013 Ryan Case. All rights reserved.
//

#import "AppDelegate.h"
#import "TouchViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    TouchViewController *tvc = [[TouchViewController alloc] init];
    [[self window] setRootViewController:tvc];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    // Preprocessor macro that adds debug code as long as it's encapsulated in the #idef / #endif blocks
//#ifdef VIEW_DEBUG
//    NSLog(@"%@", [[self window] performSelector:@selector(recursiveDescription)]);
//#endif
    
    return YES;
}

@end
