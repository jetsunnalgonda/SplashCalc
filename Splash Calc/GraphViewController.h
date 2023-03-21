//
//  SPTResultsVC_PageTwo.h
//  SPT Rocks
//
//  Created by Haluk Isik on 22/04/14.
//  Copyright (c) 2014 Haluk Isik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Splash_Calc-Bridging-Header.h"
#import "Splash_Calc_Widget-Bridging-Header.h"


@interface GraphViewController : UIViewController <CPTPlotDataSource> //, UIGestureRecognizerDelegate>
@property NSUInteger pageIndex;
@property (nonatomic, strong) CPTGraphHostingView *hostView;

@property (nonatomic, strong) NSArray *results;
@property (nonatomic, strong) NSArray *graphTitles;

@property (nonatomic, strong) NSArray *program;
@property (nonatomic, strong) NSArray *stack;
@property (nonatomic, strong) id values;

-(IBAction)unwindFromSettings:(UIStoryboardSegue *) unwindSegue;

@end
