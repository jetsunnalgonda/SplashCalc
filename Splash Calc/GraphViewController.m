//
//  SPTResultsVC_PageTwo.m
//  SPT Rocks
//
//  Created by Haluk Isik on 22/04/14.
//  Copyright (c) 2014 Haluk Isik. All rights reserved.
//

#import "GraphViewController.h"
#import "Splash_Calc-Swift.h"

@interface GraphViewController () <CPTScatterPlotDelegate, CPTPlotSpaceDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) CPTPlotSpaceAnnotation *symbolTextAnnotation;
@property (nonatomic, strong) CPTPlotSpaceAnnotation *annotation;
@property (nonatomic, strong) CPTLayerAnnotation *layerAnnotation;
@property (nonatomic, strong) NSString *annotationText;
@property (nonatomic, strong) NSMutableArray *dataLabelIndexes;
@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, strong) CPTScatterPlot *aaplPlot;
@property (nonatomic, strong) CPTXYPlotSpace *plotSpace;
@property (nonatomic, strong) CPTTextLayer *textLayer;
@property (nonatomic, strong) NSMutableDictionary *points;

@property (nonatomic, strong) CalculatorBrain *brain;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic) CGFloat precision, lowerBound, upperBound, startZoomLevel, maxZoomLevel;

@end

@implementation GraphViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSMutableArray *)dataLabelIndexes
{
    if (!_dataLabelIndexes) {
        _dataLabelIndexes = [@[@"-1", @"0"] mutableCopy];
    }
    return _dataLabelIndexes;
}

- (NSArray *)results
{
    if (!_results) {
        _results = @[@"1"];
    }
    return _results;
}

//- (id)values
//{
//    if (!_values) {
//        _values = @{@"$x":@(1.0)};
//    }
//    return _values;
//}

- (void)setValues:(id)values
{
    self.brain.variableValues = values;
}

//- (NSArray *)program
//{
//    if (!_program) {
//        self.program = @[@"?"];
//    }
//    return self.program;
//}

- (void)setProgram:(NSArray *)program
{
    self.brain.program = program;
}

- (void)setStack:(NSArray *)stack
{
    self.brain.parseStack = stack;
}

- (CalculatorBrain *)brain
{
    if (!_brain) {
        _brain = [CalculatorBrain newInstance];
    }
    return _brain;
}

//- (instancetype) init {
//    self = [super init];
//    
//    if (self) {
//        CalculatorBrain *brain = [[CalculatorBrain alloc] init];
//    }
//    
//    return self;
//}

#pragma mark - View Controller Life Cycle

- (void)readUserDefaults
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *settings = (NSArray *)[userDefaults objectForKey:@"defaultGraphSettings"];
    NSArray *defaults = @[@(20.0), @(-10.0), @(10.0), @(0.2), @(5.0)];
    NSArray *currentSettings  = @[@(self.precision), @(self.lowerBound), @(self.upperBound), @(self.startZoomLevel), @(self.maxZoomLevel)];
    if (settings == nil) {
        NSLog(@"settings nil");
        [userDefaults setObject:defaults forKey:@"defaultGraphSettings"];
        settings = (NSArray *)[userDefaults objectForKey:@"defaultGraphSettings"];
    }
    self.precision = ((NSNumber *)settings[0]).floatValue;
    self.lowerBound = ((NSNumber *)settings[1]).floatValue;
    self.upperBound = ((NSNumber *)settings[2]).floatValue;
    self.startZoomLevel = ((NSNumber *)settings[3]).floatValue;
    self.maxZoomLevel = ((NSNumber *)settings[4]).floatValue;
    
    if (self.startZoomLevel > 0.5) {
        self.startZoomLevel = round(self.startZoomLevel);
    } else {
        self.startZoomLevel = -round((1 / round(self.startZoomLevel - 2)) * 100) / 100;
    }
    if (self.maxZoomLevel > 0.5) {
        self.maxZoomLevel = round(self.maxZoomLevel);
    } else {
        self.maxZoomLevel = -round((1 / round(self.maxZoomLevel - 2)) * 100) / 100;
    }
    self.precision = round((1 / self.precision) * 100) / 100;
    
    
    NSLog(@"precision : %f", self.precision);
    NSLog(@"lowerBound : %f", self.lowerBound);
    NSLog(@"upperBound : %f", self.upperBound);
    NSLog(@"startZoomLevel : %f", self.startZoomLevel);
    NSLog(@"maxZoomLevel : %f", self.maxZoomLevel);
    
    NSLog(@"settings = %@", settings);
    NSLog(@"currentSettings = %@", currentSettings);
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"view will appear called");
    
    [self readUserDefaults];
//    [self disposeOfResources];
//    [self loadGraph];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    //[[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification
    //                                                    object:[UIDevice currentDevice]];
}

- (void)viewWillLayoutSubviews
{
    [self adjustSize];
}

- (void)adjustSize
{
//    CGFloat navigationHeight = self.navigationController.navigationBar.frame.size.height;
//    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat topHeight = self.topLayoutGuide.length;
//    NSLog(@"self.topLayoutGuide.length = %f", self.topLayoutGuide.length);
//    NSLog(@"statusBarHeight = %f", statusBarHeight);
//    NSLog(@"navigationHeight = %f", navigationHeight);
    
    self.view.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y + topHeight,
                                 self.view.bounds.size.width, self.view.bounds.size.height - topHeight);
    
    CGFloat aspectRatio = self.view.frame.size.width / self.view.frame.size.height;
    
    // Plot length that we defined in settings
//    CGFloat plotLength = self.upperBound - self.lowerBound;
//    
//    CGFloat startX = (self.lowerBound * (2.0 - self.startZoomLevel)) * aspectRatio;
//    CGFloat startY = self.lowerBound * (2.0 - self.startZoomLevel);
//    
//    CGFloat lengthX = plotLength * self.startZoomLevel * aspectRatio;
//    CGFloat lengthY = plotLength * self.startZoomLevel;
//    
//    CGFloat startXMax = (self.lowerBound * (2.0 - self.maxZoomLevel)) * aspectRatio;
//    CGFloat startYMax = self.lowerBound * (2.0 - self.maxZoomLevel);
//    
//    CGFloat lengthXMax = plotLength * self.maxZoomLevel * aspectRatio;
//    CGFloat lengthYMax = plotLength * self.maxZoomLevel;

    
    // Set starting zoom level and maximum zoom level
    self.plotSpace.xRange = [CPTPlotRange
                             plotRangeWithLocation:@(self.lowerBound * self.startZoomLevel * aspectRatio)
                             length:@((self.upperBound - self.lowerBound) * self.startZoomLevel * aspectRatio)];
    self.plotSpace.yRange = [CPTPlotRange
                             plotRangeWithLocation:@(self.lowerBound * self.startZoomLevel)
                             length:@((self.upperBound - self.lowerBound) * self.startZoomLevel)];
    
    self.plotSpace.globalXRange = [CPTPlotRange
                                   plotRangeWithLocation:@(self.lowerBound * self.maxZoomLevel* aspectRatio)
                                   length:@((self.upperBound - self.lowerBound) * self.maxZoomLevel * aspectRatio)];
    self.plotSpace.globalYRange = [CPTPlotRange
                                   plotRangeWithLocation:@(self.lowerBound * self.maxZoomLevel)
                                   length:@((self.upperBound - self.lowerBound) * self.maxZoomLevel)];
}



//static const NSUInteger plotLength = 20;
//static const CGFloat precision = 0.05f;

//static const CGFloat numberOfRecords = (CGFloat)plotLength / precision;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = false;
    
    self.points = [[NSMutableDictionary alloc] init];
    self.view.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];


    [self readUserDefaults];
    
    [self loadGraph];
    
    
    self.graph.defaultPlotSpace.delegate = self;
    self.aaplPlot.delegate = self;
    
}

- (void)loadGraph
{
    NSLog(@"self.brain.program = %@", self.brain.program);
    NSLog(@"self.program = %@", self.program);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [self.spinner startAnimating];
        
        CGFloat numberOfRecords = (CGFloat)(self.upperBound - self.lowerBound) / self.precision;
        
        // Preload points dictionary
        for (int i = 0; i <= numberOfRecords; i++)
        {
            CGFloat indexFloat = (CGFloat)i;
            CGFloat xValue = (indexFloat - numberOfRecords / 2) * self.precision;
            
            if (self.brain.program == nil || [self.brain.program count] == 0) {
                
                self.brain.variableValuesNS[@"$x"] = @(xValue);
                [self.brain setDictionary];
                
                NSNumber *result = [self.brain parseAndReturnValue];
                if (result != nil) {
                    self.points[@(xValue)] = result;
                }
            } else {
                self.brain.variableValuesNS[@"x"] = @(xValue);
                [self.brain setDictionary];
                
                NSNumber *result = [self.brain evaluateAndReportErrors];
                if (result != nil) {
                    self.points[@(xValue)] = result;
                }
            }
            
//            for (int i=0; i<10000000; i++) {
//
//            }
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
            [self initPlot];
            
            CGFloat navigationHeight = self.navigationController.navigationBar.frame.size.height;
            CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
            
            self.view.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y,
                                         self.view.bounds.size.width, super.view.bounds.size.height + navigationHeight + statusBarHeight);
            NSLog(@"init plot done");
            
        });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [self disposeOfResources];
}

- (void)disposeOfResources
{
    self.hostView = nil;
    self.graphTitles = nil;
    
    self.symbolTextAnnotation = nil;
    self.annotation = nil;
    self.layerAnnotation = nil;
    self.annotationText = nil;
    self.graph = nil;
    self.aaplPlot = nil;
    self.plotSpace = nil;
    self.textLayer = nil;
}
#pragma mark - Chart behavior
-(void)initPlot {
    [self configureHost];
    [self configureGraph];
    [self configurePlots];
    [self configureAxes];
}

-(void)configureHost {
    //self.hostView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:self.view.bounds];
	self.hostView.allowPinchScaling = YES;
	[self.view addSubview:self.hostView];
    //self.view.autoresizesSubviews = YES;
    self.hostView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleLeftMargin |
                                      UIViewAutoresizingFlexibleRightMargin |
                                      UIViewAutoresizingFlexibleHeight);
    // Width constraint, parent view width
    /*[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.hostView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:2
                                                           constant:0]];
     */
}

-(void)configureGraph {
	// 1 - Create the graph
	self.graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    
    // THEME
	[self.graph applyTheme:[CPTTheme themeNamed:kCPTPlainBlackTheme]];
    
    self.graph.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.4
                                                                       green:0.4
                                                                        blue:0.4
                                                                       alpha:1.0]];
    
    self.graph.plotAreaFrame.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.4
                                                                                     green:0.4
                                                                                      blue:0.4
                                                                                     alpha:1.0]];
    
    CPTMutableLineStyle *borderLineStyle = [CPTMutableLineStyle lineStyle];
    borderLineStyle.lineColor = [CPTColor whiteColor];
    borderLineStyle.lineWidth = CPTFloat(1.0);
    
    self.graph.plotAreaFrame.borderLineStyle = borderLineStyle;
    self.graph.plotAreaFrame.cornerRadius    = CPTFloat(2.0);
    
    /////////////////////
    
	self.hostView.hostedGraph = self.graph;
	// 2 - Set graph title
	NSString *title = self.graphTitles[self.pageIndex-1];
//    NSLog(@"graph titles: %@", self.graphTitles);
//    NSLog(@"page index: %li", (unsigned long)self.pageIndex);
	self.graph.title = title;
	// 3 - Create and set text style
	CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
	titleStyle.color = [CPTColor whiteColor];
	titleStyle.fontName = @"Helvetica-Bold";
	titleStyle.fontSize = 16.0f;
	self.graph.titleTextStyle = titleStyle;
	self.graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
	self.graph.titleDisplacement = CGPointMake(0.0f, 20.0f);


	// 4 - Set padding for plot area
	[self.graph.plotAreaFrame setPaddingLeft:0.0f];
	[self.graph.plotAreaFrame setPaddingBottom:0.0f];

	// 5 - Enable user interactions for plot space
	self.plotSpace = (CPTXYPlotSpace *) self.graph.defaultPlotSpace;
	self.plotSpace.allowsUserInteraction = YES;
}

-(void)configurePlots {
	// 1 - Get graph and plot space
	CPTGraph *graph = self.hostView.hostedGraph;
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;

	// 2 - Create the plot 
	self.aaplPlot = [[CPTScatterPlot alloc] init];
	self.aaplPlot.dataSource = self;
	self.aaplPlot.identifier = @"plot 1"; //CPDTickerSymbolAAPL;
    self.aaplPlot.plotSymbolMarginForHitDetection = 5.0f;

	CPTColor *aaplColor = [CPTColor colorWithComponentRed:0.95f green:0.16f blue:0.13f alpha:1.0f];
	[graph addPlot:self.aaplPlot toPlotSpace:plotSpace];

	// 3 - Set up plot space
	[plotSpace scaleToFitPlots:[NSArray arrayWithObjects:self.aaplPlot, nil]];
	CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
	[xRange expandRangeByFactor:@(1.1f)];
	plotSpace.xRange = xRange;
	CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
	[yRange expandRangeByFactor:@(1.2f)];
	plotSpace.yRange = yRange;
	// 4 - Create styles and symbols
	CPTMutableLineStyle *aaplLineStyle = [self.aaplPlot.dataLineStyle mutableCopy];
	aaplLineStyle.lineWidth = 2.5;
	aaplLineStyle.lineColor = aaplColor;
	self.aaplPlot.dataLineStyle = aaplLineStyle;
	CPTMutableLineStyle *aaplSymbolLineStyle = [CPTMutableLineStyle lineStyle];
	aaplSymbolLineStyle.lineColor = aaplColor;
	CPTPlotSymbol *aaplSymbol = [CPTPlotSymbol ellipsePlotSymbol];
	aaplSymbol.fill = [CPTFill fillWithColor:aaplColor];
	aaplSymbol.lineStyle = aaplSymbolLineStyle;
	aaplSymbol.size = CGSizeMake(6.0f, 6.0f);
	//self.aaplPlot.plotSymbol = aaplSymbol;

    // Put an area gradient under the plot above
    CPTColor *areaColor = [CPTColor colorWithComponentRed:0.95
                                                    green:0.66
                                                     blue:0.63
                                                    alpha:0.3];
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor
                                                            endingColor:[CPTColor clearColor]];
    areaGradient.angle = -90.0f;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    self.aaplPlot.areaFill = areaGradientFill;
    self.aaplPlot.areaBaseValue = @([@"0.00" floatValue]);

    // Annotation
    self.textLayer = [[CPTTextLayer alloc] init];
    self.symbolTextAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:self.plotSpace  anchorPlotPoint:@[@1, @1]];
    self.layerAnnotation = [[CPTLayerAnnotation alloc] initWithAnchorLayer:graph];

    //[self.hostView.layer addSublayer:self.textLayer];

}

-(void)configureAxes {

    // Find maximum and minimum values of X axis
//    NSLog(@"results = %@", self.results);
    CGFloat maxValue = 1.0f;
    for (NSString *string in self.results)
    {
        NSInteger currentValue = [string intValue];
//        NSLog(@"currentValue = %li", (long)currentValue);
        if (currentValue > maxValue)
            maxValue = currentValue;
    }
    CGFloat minValue = maxValue;
    for (NSString *string in self.results)
    {
        NSInteger currentValue = [string intValue];
//        NSLog(@"currentValue = %li", (long)currentValue);
        if ((currentValue < minValue) && currentValue > 1)
            minValue = currentValue;
    }
    NSInteger numberOfLayers = [self.results count] ? [self.results count] : 1;
    if (ceil(maxValue-minValue)==0) maxValue = maxValue+minValue;
    
//    maxValue = 50;
//    minValue = -50;
    
    NSLog(@"maxValue is %li", (long)maxValue);
    NSLog(@"minValue is %li", (long)minValue);
    NSLog(@"number of layers is %li", (long)numberOfLayers);

	// 1 - Create styles
	CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
	axisTitleStyle.color = [CPTColor whiteColor];
	axisTitleStyle.fontName = @"Helvetica-Bold";
	axisTitleStyle.fontSize = 12.0f;
	CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
	axisLineStyle.lineWidth = 2.0f;
	axisLineStyle.lineColor = [CPTColor whiteColor];
	CPTMutableTextStyle *axisTextStyle = [[CPTMutableTextStyle alloc] init];
	axisTextStyle.color = [CPTColor whiteColor];
	axisTextStyle.fontName = @"Helvetica-Bold";
	axisTextStyle.fontSize = 11.0f;
	CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
	tickLineStyle.lineColor = [CPTColor whiteColor];
	tickLineStyle.lineWidth = 2.0f;
	CPTMutableLineStyle *gridLineStyle = [CPTMutableLineStyle lineStyle];
    gridLineStyle.lineWidth = 0.75;
    gridLineStyle.lineColor = [[CPTColor grayColor] colorWithAlphaComponent:0.6]; // [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
    
	tickLineStyle.lineColor = [CPTColor blackColor];
	tickLineStyle.lineWidth = 1.0f;

	// 2 - Get axis set
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;

	// 3 - Configure x-axis
	CPTAxis *x = axisSet.xAxis;
//	x.title = self.graphTitles[self.pageIndex-1];
    x.title = @"x";
	x.titleTextStyle = axisTitleStyle;
	x.titleOffset = -35.0f;
	x.axisLineStyle = axisLineStyle;
    x.majorIntervalLength = @(0.5);
    x.majorGridLineStyle = gridLineStyle;
	x.labelingPolicy = CPTAxisLabelingPolicyNone;
	x.labelTextStyle = axisTextStyle;
    x.labelOffset = 16.0f;
	x.majorTickLineStyle = axisLineStyle;
	x.majorTickLength = 4.0f;
    x.minorTickLength = 2.0f;
	x.tickDirection = CPTSignPositive; //CPTSignNegative;
    NSInteger minorIncrementX = ceil((maxValue-minValue)/numberOfLayers);//10;
    
//    NSLog(@"max-min = %f", maxValue-minValue);
	NSInteger majorIncrementX = ceil(minorIncrementX*2.0f);
//    NSLog(@"major increment X is %li", (long)majorIncrementX);
//    NSLog(@"minor increment X is %li", (long)minorIncrementX);

	CGFloat xMax = maxValue; //70.0f;  // should determine dynamically based on max price
	NSMutableSet *xLabels = [NSMutableSet set];
	NSMutableSet *xMajorLocations = [NSMutableSet set];
	NSMutableSet *xMinorLocations = [NSMutableSet set];
	for (NSInteger j = minorIncrementX; j <= xMax; j += minorIncrementX) {
		NSUInteger mod = j % majorIncrementX;
//        NSLog(@"j = %li", (long)j);
//        NSLog(@"majorIncrementX = %li", (long)majorIncrementX);
//        NSLog(@"minorIncrementX = %li", (long)minorIncrementX);
		if (mod == 0) {
			CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%li", (long)j] textStyle:x.labelTextStyle];
			NSNumber *location = @(j);
			label.tickLocation = location;
			label.offset = -x.majorTickLength - x.labelOffset;
			if (label) {
				[xLabels addObject:label];
			}
			[xMajorLocations addObject:location];
		} else {
			[xMinorLocations addObject:@(j)];
		}
	}

    
    x.axisLabels = xLabels;
    x.majorTickLocations = xMajorLocations;
	x.minorTickLocations = xMinorLocations;
    
	//x.majorTickLocations = xLocations;
	// 4 - Configure y-axis
	CPTAxis *y = axisSet.yAxis;
	y.title = @"y";
	y.titleTextStyle = axisTitleStyle;
	y.titleOffset = -30.0f;
	y.axisLineStyle = axisLineStyle;
    y.majorIntervalLength = @(0.5);
	y.majorGridLineStyle = gridLineStyle;
	y.labelingPolicy = CPTAxisLabelingPolicyNone;
	y.labelTextStyle = axisTextStyle;
	y.labelOffset = 16.0f;
	y.majorTickLineStyle = axisLineStyle;
	y.majorTickLength = 4.0f;
	y.minorTickLength = 2.0f;
	y.tickDirection = CPTSignPositive;
	NSInteger majorIncrement = 1;
	NSInteger minorIncrement = 1;
	CGFloat yMax = [self.results count]; // 70.0f;  // should determine dynamically based on max price
	NSMutableSet *yLabels = [NSMutableSet set];
	NSMutableSet *yMajorLocations = [NSMutableSet set];
	NSMutableSet *yMinorLocations = [NSMutableSet set];
	for (NSInteger j = minorIncrement; j <= yMax; j += minorIncrement) {
		NSUInteger mod = j % majorIncrement;
		if (mod == 0) {
			CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%li", (long)j] textStyle:y.labelTextStyle];
			NSNumber *location = @(j);
			label.tickLocation = location;
			label.offset = -y.majorTickLength - y.labelOffset;
			if (label) {
				[yLabels addObject:label];
			}
			[yMajorLocations addObject: location];
		} else {
			[yMinorLocations addObject:@(j)];
		}
	}
	y.axisLabels = yLabels;
	y.majorTickLocations = yMajorLocations;
	y.minorTickLocations = yMinorLocations;

    CGFloat aspectRatio = self.view.frame.size.width / self.view.frame.size.height;
    
    // Set starting zoom level and maximum zoom level
    self.plotSpace.xRange = [CPTPlotRange
                             plotRangeWithLocation:@(-10.0 * aspectRatio)
                             length:@(20.0 * aspectRatio)];
    self.plotSpace.yRange = [CPTPlotRange
                             plotRangeWithLocation:@(-10.0f)
                             length:@(20.0f)];

    self.plotSpace.globalXRange = [CPTPlotRange
                             plotRangeWithLocation:@(-10.0 * aspectRatio)
                             length:@(20.0 * aspectRatio)];
    self.plotSpace.globalYRange = [CPTPlotRange
                             plotRangeWithLocation:@(-10.0f)
                             length:@(20.0f)];
    
//    self.plotSpace.xRange = [CPTPlotRange
//                             plotRangeWithLocation:@(0.0f-minorIncrementX)
//                             length:@(maxValue+minValue+minorIncrementX)];
//    self.plotSpace.yRange = [CPTPlotRange
//                             plotRangeWithLocation:@(-2.0f)
//                             length:@([self.results count]+3)];
    //self.plotSpace.GlobalXRange = [CPTPlotRange
    //                               plotRangeWithLocation:CPTDecimalFromFloat(minValue*5)
    //                               length:CPTDecimalFromUnsignedInteger(maxValue*5)];
    //self.plotSpace.GlobalYRange = [CPTPlotRange
    //                               plotRangeWithLocation:CPTDecimalFromFloat(-[self.results count])
    //                               length:CPTDecimalFromUnsignedInteger([self.results count])];
    
    x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
}

#pragma mark - Rotation
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

#pragma mark - CPTPlotDataSource methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    CGFloat numberOfRecords = (CGFloat)(self.upperBound - self.lowerBound) / self.precision;
    return (NSUInteger)numberOfRecords;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{

//    CGFloat indexFloat = (CGFloat)index;
//    CGFloat increment = (indexFloat - numberOfRecords / 2) * precision;
//    
//	switch (fieldEnum) {
//        case CPTScatterPlotFieldY: {
//            self.brain.variableValuesNS[@"$x"] = @(increment);
//            [self.brain setDictionary];
//            NSLog(@"self.brain.variableValues = %@", self.brain.variableValues);
//            NSNumber *result = [self.brain parseAndReturnValue];
//            
//            for (int i=0; i<10000000; i++) {
//                
//            }
//            return result;
//
//            break;
//        }
//
//		case CPTScatterPlotFieldX:
//
//            return @(increment);
//			break;
//	}

    CGFloat numberOfRecords = (CGFloat)(self.upperBound - self.lowerBound) / self.precision;
    CGFloat indexFloat = (CGFloat)index;
    CGFloat increment = (indexFloat - numberOfRecords / 2) * self.precision;
    
    switch (fieldEnum) {
        case CPTScatterPlotFieldY: {
            
            return self.points[@(increment)];
            
            break;
        }
            
        case CPTScatterPlotFieldX:
            
            return @(increment);
            break;
    }

    
    return nil;
    
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    if ([plot.identifier isEqual:@"plot 1"])
    {
//        NSLog(@"data label for plot, index = %lu", (unsigned long)index);
//        NSLog(@"data label indexes 0 -> %@, 1 -> %@", self.dataLabelIndexes[0], self.dataLabelIndexes[1]);

        CPTTextLayer *selectedText = [CPTTextLayer layer];
        if (index == [self.dataLabelIndexes[1] integerValue]) {
//            NSLog(@"inside if, data label indexes 0 -> %@, 1 -> %@", self.dataLabelIndexes[0], self.dataLabelIndexes[1]);
            //[self.aaplPlot addAnimation:fadeOutAnimation forKey:@"animateOpacity"];
            CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeOutAnimation.duration = 1.0f;
            fadeOutAnimation.beginTime = CACurrentMediaTime()+2.0f;
            fadeOutAnimation.removedOnCompletion = NO;
            fadeOutAnimation.fillMode = kCAFillModeForwards;
            fadeOutAnimation.toValue = [NSNumber numberWithFloat:0.0f];
            
            [selectedText addAnimation:fadeOutAnimation forKey:@"animateOpacity"];
            //[selectedText removeAllAnimations];
            
            selectedText.text = @"";
            //selectedText.text = self.annotationText; // @"test text";
            CPTMutableTextStyle *labelTextStyle = [CPTMutableTextStyle textStyle];
            labelTextStyle.fontSize = 16.0f;
            labelTextStyle.fontName = @"Helvetica-Bold";
            labelTextStyle.color = [CPTColor whiteColor];
            selectedText.textStyle = labelTextStyle;
            selectedText.text = self.annotationText;
            return selectedText;
            
        }
        else if (index == [self.dataLabelIndexes[0] integerValue]) {
            selectedText.text = @""; //test text";
            CPTMutableTextStyle *labelTextStyle = [CPTMutableTextStyle textStyle];
            labelTextStyle.fontSize = 10;
            labelTextStyle.fontName = @"Helvetica Neue";
            labelTextStyle.color = [CPTColor whiteColor];
            selectedText.textStyle = labelTextStyle;
            return selectedText;
        }
        //self.dataLabelIndexes[0] = @(index);

    }
    return nil;
}



#pragma mark - Gesture recognizer


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    NSLog(@"should be required to fail");
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    NSLog(@"gesture recognizer should begin");

    return YES;
}
- (BOOL)handleSingleTap:(UITapGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch {
    
    NSLog(@"sdfghj");
    if ([touch.view isKindOfClass:[UIControl class]]) { // <<<< EXC_BAD_ACCESS HERE
        // we touched a button, slider, or other UIControl
        return NO; // ignore the touch
    }
    [self.view endEditing:YES]; // dismiss the keyboard
    return YES; // handle the touch
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


#pragma mark -

-(CGRect)currentScreenBoundsDependOnOrientation
{
    
    CGRect screenBounds = [UIScreen mainScreen].bounds ;
    CGFloat width = CGRectGetWidth(screenBounds)  ;
    CGFloat height = CGRectGetHeight(screenBounds) ;
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(UIInterfaceOrientationIsPortrait(interfaceOrientation)){
        screenBounds.size = CGSizeMake(width, height);
    }else if(UIInterfaceOrientationIsLandscape(interfaceOrientation)){
        screenBounds.size = CGSizeMake(height, width);
    }
    return screenBounds ;
}

-(IBAction)unwindFromSettings:(UIStoryboardSegue *) unwindSegue
{
    
}

@end
