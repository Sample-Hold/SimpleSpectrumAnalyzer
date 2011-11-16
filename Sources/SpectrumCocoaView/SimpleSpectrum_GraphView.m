//
//  SimpleSpectrum_GraphView.m
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrum_GraphView.h"

@implementation SimpleSpectrum_GraphView

#define kDefaultMinHertz	12
#define kDefaultMaxHertz	22050
#define kDefaultGain        20
#define kLogBase            2
#define kNumGridLines		11
#define kNumDBLines			4
#define kDBAxisGap			35
#define kFreqAxisGap		17
#define kRightMargin		10
#define kTopMargin			5

#pragma mark ____ (INIT /) DEALLOC ____
-(id)initWithFrame:(NSRect)frameRect
{
    if(self = [super initWithFrame:frameRect]) {
        
        // Initialize frame that is used for drawing the graph content
		mGraphFrame = NSMakeRect(kDBAxisGap,																	kFreqAxisGap, 
                                frameRect.size.width - kDBAxisGap - kRightMargin, 
                                frameRect.size.height - kFreqAxisGap - kTopMargin);
		
		// Initialize the text attributes for the db and frequency axis
		NSMutableParagraphStyle *dbLabelStyle = [[NSMutableParagraphStyle alloc] init];
		[dbLabelStyle setParagraphStyle: [NSParagraphStyle defaultParagraphStyle]];
		[dbLabelStyle setAlignment:NSRightTextAlignment];
		
		mDBAxisStringAttributes = 
            [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize: 9], NSFontAttributeName, [dbLabelStyle autorelease], NSParagraphStyleAttributeName,
                [NSColor colorWithDeviceWhite: .1 alpha: 1], 
                NSForegroundColorAttributeName, nil] retain];
		
		NSMutableParagraphStyle *freqLabelStyle = [[NSMutableParagraphStyle alloc] init];
		[freqLabelStyle setParagraphStyle: [NSParagraphStyle defaultParagraphStyle]];
		[freqLabelStyle setAlignment:NSCenterTextAlignment];
		
		mFreqAxisStringAttributes = 
            [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize: 9], NSFontAttributeName, [freqLabelStyle autorelease], NSParagraphStyleAttributeName,
                [NSColor colorWithDeviceWhite: .1 alpha: 1], 
                NSForegroundColorAttributeName, nil] retain];
		
		mActiveWidth = [self locationForFrequencyValue: kDefaultMaxHertz] - mGraphFrame.origin.x - .5;

        mSpectrum = malloc(DEFAULT_HSCALE * sizeof(Float32));
        mScale.h = DEFAULT_HSCALE;
        mScale.v = DEFAULT_VSCALE;

        [self setPostsFrameChangedNotifications:YES];
        
        // for testing purpose
        [self fillSpectrumWithTestCoordinates];
    }
    
    return self;
}

-(void)dealloc
{
    free(mSpectrum);
    
    [mDBAxisStringAttributes release];
	[mFreqAxisStringAttributes release];
	[mCurvePath release];
	[curveColor release];
	
	[mBackgroundCache release];

    [super dealloc];
}

#pragma mark ____ PUBLIC METHODS ____
-(void)resetScale:(Point)scale
{
    assert(scale.h > 0);
    mScale = scale;
    if(mSpectrum)
        free(mSpectrum);
    mSpectrum = malloc(scale.h * sizeof(Float32));
}

/* Compute the pixel location on the y axis within the graph frame for the decibel value argument */
- (double) locationForDBValue: (double) value {
	double step		= mGraphFrame.size.height / (kDefaultGain * 2);
	double location = (value + kDefaultGain) * step;	
	
	return mGraphFrame.origin.y + location;
}

/* Compute the logarithm of a number with an arbitrary base */
double logValueForNumber(double number, double base) {
	return log (number) / log(base);
}

/* Compute the pixel location on the x axis within the graph frame for the frequency value argument */
- (double) locationForFrequencyValue: (double) value {	
	// how many pixels are in one base power increment?
	double pixelIncrement = mGraphFrame.size.width / kNumGridLines;
	double location = logValueForNumber(value/kDefaultMinHertz, kLogBase) * pixelIncrement;
	
	location = floor(location + mGraphFrame.origin.x) + .5;
	return location;
}

/* Compute the decibel value at a specific y coordinate in the graph */
- (double) dbValueForLocation: (float) location {
	double step	= mGraphFrame.size.height / (kDefaultGain * 2);// number of pixels per db
	return ((location - mGraphFrame.origin.y)/ step) - kDefaultGain;
}

/* Compute the pixel value of a specific grid line */
double valueAtGridIndex(double index) {
	return kDefaultMinHertz * pow(kLogBase, index);
}

/* Compute the frequency value of a specific pixel location in the graph */
- (double) freqValueForLocation: (float) location {
	double pixelIncrement = mGraphFrame.size.width / kNumGridLines;
	
	return valueAtGridIndex((location - mGraphFrame.origin.x - .5)/pixelIncrement);
}

/* returns a string for a specific double value (for displaying axis labels) */
- (NSString *) stringForValue:(double) value {		
	NSString * theString;
	double temp = value;
	
	if (value >= 1000)
		temp = temp / 1000;
	
	temp = (floor(temp *100))/100;	// chop everything after 2 decimal places
    // we don't want trailing 0's
	
	//if we do not have trailing zeros
	if (floor(temp) == temp)
		theString = [NSString localizedStringWithFormat: @"%.0f", temp];
	else 	// if we have only one digit
		theString = [NSString localizedStringWithFormat: @"%.1f", temp];
	
	return theString;
}

/* draws the DB grid lines and axis labels */
- (void)drawDBScale {
	NSPoint startPoint, endPoint;
	int index, value;
	
	[[NSColor whiteColor] set];
	// figure out how many grid divisions to use for the gain axis
	for (index = -kNumDBLines; index <= kNumDBLines; index ++) {
		value = index * (kDefaultGain / kNumDBLines);
		startPoint = NSMakePoint(mGraphFrame.origin.x, floor([self locationForDBValue: index * (kDefaultGain/kNumDBLines)]) + .5);
		endPoint   = NSMakePoint(mGraphFrame.origin.x + mActiveWidth, startPoint.y);
		
		if (index > -kNumDBLines && index < kNumDBLines) {
			if (index == 0) {
				[[NSColor colorWithDeviceWhite: .2 alpha: .3] set];
				[NSBezierPath strokeLineFromPoint: startPoint toPoint: endPoint];
				[[NSColor whiteColor] set];
			} else
				[NSBezierPath strokeLineFromPoint: startPoint toPoint: endPoint];
		}
		[[NSString localizedStringWithFormat: @"%d db", value] drawInRect: NSMakeRect(0, startPoint.y - 4, mGraphFrame.origin.x - 4, 11) withAttributes: mDBAxisStringAttributes];
	}
}

/* Draws the frequency grid lines on a logarithmic scale */
- (void) drawMajorGridLines {
	int 		index;
	double 		location, value;
	float		labelWidth = mGraphFrame.origin.x - 2;
	
	NSColor *gridColor = [[NSColor redColor] colorWithAlphaComponent: .15];
	BOOL firstK = YES;	// we only want a 'K' label the first time a value is over 1000
    
	for (index = 0; index <= kNumGridLines; index++) {
		value = valueAtGridIndex(index);
		location = [self locationForFrequencyValue: value];
		
		
		if (index > 0 && index < kNumGridLines) {	
			[gridColor set];
			[NSBezierPath strokeLineFromPoint: NSMakePoint(location, mGraphFrame.origin.y)
									  toPoint: NSMakePoint(location, floor(mGraphFrame.origin.y + mGraphFrame.size.height - 2) +.5)];
			
			NSString *s = [self stringForValue: value];
			if (value >= 1000 && firstK) {
				s = [s stringByAppendingString: @"K"];
				firstK = NO;
			}
			[s drawInRect: NSMakeRect(location - 3 - labelWidth/2, 0, labelWidth, 12) withAttributes: mFreqAxisStringAttributes];
		} else if (index == 0) {	// append hertz label to first frequency
			[[[self stringForValue: value] stringByAppendingString: @"Hz"] drawInRect: NSMakeRect(location - labelWidth/2, 0, labelWidth, 12) withAttributes: mFreqAxisStringAttributes];
		} else {	// always label the last grid marker the maximum hertz value
			[[[self stringForValue: kDefaultMaxHertz] stringByAppendingString: @"K"] drawInRect: NSMakeRect(location - labelWidth/2 - 12, 0, labelWidth + kRightMargin, 12) withAttributes: mFreqAxisStringAttributes];
		}
	}
}

/* ------- NOTES ON DRAWING -------
 For the purposes of this sample, we do only the most basic performance optimizations in the interest 
 of keeping this sample reasonably simple such as caching the background graph and labels in an image.
 
 There are several additional optimizations that could be performed in order to enhance graphic speed
 
 1) This is a non-opaque view. Every time it draws, it is necessary to redraw the window background before
 drawing the view contents. Drawing a solid fill color in the background of the view and overriding -(void) isOpaque
 to return YES would result in some speedup
 2) The view is drawn anti-aliased. It is probably unneccesary to draw anti-aliased when the mouse is being dragged.
 Calling setShouldAntialias: NO on the NSGraphicsContext when the mouse is dragging begins, and setting it back to
 YES when dragging ends could result in a substatial speed increase. Likewise, the control point could always be drawn
 with anti-aliasing off because it is drawn aligned to pixel boundaries
 3) Drawing the curve could be done with Quartz to avoid the overhead of NSBezierPath
 4) The curve should be drawn with increased resolution around the control point and less resolution farther away. The fewer
 points in the curve plot, the faster it will draw
 5) Drawing the curve without transparency may increase the render time
 
 Remember that before doing any optimization, make sure that your code is working correctly first, and then profile with Shark
 to determine which areas could benefit from the most optimization. Premature optimization can actually result in slower code.
 */
- (void)drawRect:(NSRect)rect
{
	if (!mBackgroundCache) {
		mBackgroundCache = [[NSImage alloc] initWithSize: [self frame].size];
        
		[mBackgroundCache lockFocus];
		// fill the graph area
		[[NSColor colorWithDeviceWhite: .90 alpha: 1.0] set];
		NSRectFill(NSIntersectionRect(rect, NSMakeRect(mGraphFrame.origin.x, mGraphFrame.origin.y, mActiveWidth, mGraphFrame.size.height)));
		
		// draw the graph border
		[[NSColor whiteColor] set];
		NSRect lineRect = NSMakeRect(mGraphFrame.origin.x, mGraphFrame.origin.y-1, mActiveWidth, 1);
		NSRectFill(NSIntersectionRect(rect, lineRect));
		
		[[NSColor colorWithDeviceWhite: .46 alpha: 1] set];
		lineRect.origin.y = mGraphFrame.origin.y + mGraphFrame.size.height -1;
		NSRectFill(NSIntersectionRect(rect, lineRect));
		
		[[NSColor colorWithDeviceWhite: .75 alpha: 1] set];
		lineRect.origin.y -= 1;
		NSRectFill(NSIntersectionRect(rect, lineRect));
        
		[self drawDBScale];
		[self drawMajorGridLines];
		
		[mBackgroundCache unlockFocus];
	}
	
	[mBackgroundCache drawInRect: rect fromRect: rect operation: NSCompositeSourceOver fraction: 1.0];
	
	// draw the curve
    //	[[NSColor colorWithDeviceRed: .31 green: .37 blue: .73 alpha: .8] set];
	if (curveColor) {
		[curveColor set]; 
		[mCurvePath fill];
	}
}


/* update the graph frame when the view frame size changes */
-(void) setFrameSize: (NSSize) newSize {
	mGraphFrame.size.width = newSize.width - kDBAxisGap - kRightMargin;
	mGraphFrame.size.height= newSize.height - kFreqAxisGap - kTopMargin;
	
	mActiveWidth = [self locationForFrequencyValue: kDefaultMaxHertz] - mGraphFrame.origin.x - .5;
	
	[mBackgroundCache release];
	mBackgroundCache = nil;
    
	[super setFrameSize: newSize];
}

/* update the graph frame and edit point when the view frame changes */
-(void) setFrame: (NSRect) frameRect {
    [self setFrameSize:frameRect.size];	
}

/*	This method is called to set the frequency response values in the data that correspond to the points that we will will later be drawing
 The data argument is an array of FrequencyResponse structures. The number of items in this array is a fixed size, so we have a finite amount
 of resolution. We compute a pixelRatio which specifies how many pixels separate each frequency value
 */
-(FrequencyResponse *) prepareDataForDrawing: (FrequencyResponse *) data {
	float width = mActiveWidth;
	float rightEdge = width + mGraphFrame.origin.x;
	int	i, pixelRatio = (int) ceil(width/mScale.h);
	float location = mGraphFrame.origin.x;	// location is the x coordinate in the graph
	
	for (i = 0; i < mScale.h; i++) {
		if (location > rightEdge)	// if we have exceeded the right edge of our graph, just store the max hertz value
			data[i].mFrequency = kDefaultMaxHertz;
		else {
			float freq = [self freqValueForLocation: location];	// compute the frequency value for our location
			if (freq > kDefaultMaxHertz)						// check to make sure our computed value does not exceed our maximum hertz value
				freq = kDefaultMaxHertz;
			data[i].mFrequency = freq;
		}
		location += pixelRatio;									// increment our location counter
	}
	return data;
}

/* Draw the curve from the data */
-(void) plotData: (FrequencyResponse *) data {
	// NOTE that much of this data could be cached since it will be the same every time we draw as long as our frame size has not changed
	// We do not do this optimization in the interest of simplicity.
	float width = mActiveWidth;
	float rightEdge = width + mGraphFrame.origin.x;
	int	i, pixelRatio = (int) ceil(width/kNumberOfResponseFrequencies);	// compute how many pixels separate each db value
	float location = mGraphFrame.origin.x;
	
	if (!curveColor)
		curveColor = [[NSColor colorWithDeviceRed: .31 green: .37 blue: .73 alpha: .8] retain];
    
	[mCurvePath release];												// release previous bezier path
	mCurvePath = [[NSBezierPath bezierPath] retain];					// create a new default empty path
	[mCurvePath moveToPoint: mGraphFrame.origin];						// start the bezier path at the bottom left corner of the graph
	
	float lastDBPos = 0;												// cache the previous decibel pixel value
	for (i = 0; i < mScale.h; i++) {				
		float dbValue = 20.0*log10(mSpectrum[i]);	// compute the current decibel value
		float dbPos = 0;												
		if (dbValue < -kDefaultGain)							// constrain the current db value to our min and max gain interval
			dbPos = mGraphFrame.origin.y;
		else if (dbValue > kDefaultGain)
			dbPos = mGraphFrame.origin.y + mGraphFrame.size.height;
		else 
			dbPos = [self locationForDBValue: dbValue];					// if the current db value is within our range, compute the location
		
		if (fabsf(lastDBPos - dbPos) >= .1)								// only create a new point in our bezier path if the current db pixel value 
			[mCurvePath lineToPoint: NSMakePoint(location, dbPos)];		// differs from our previous value by .1 pixels or more
		
		lastDBPos = dbPos;												// cache current value
		location += pixelRatio;											// increment our location
		
		if (location > rightEdge) {										// if we get to the right edge of our graph, bail
			location = rightEdge;
			break;
		}
	}
	[mCurvePath lineToPoint: NSMakePoint(location, mGraphFrame.origin.y)];	// set the final point to the lower right hand corner of the graph
	[mCurvePath closePath];
	
	[self setNeedsDisplay: YES];										// mark the graph as needing to be updated
}

-(void) disableGraphCurve {													// update the view, but don't draw the curve (used when the AU is not initialized and the curve can not be retrieved)
	if (curveColor) {
		[curveColor release];
		curveColor = nil;
	}
	[self setNeedsDisplay: YES];
}

#pragma mark ____ INTERNAL METHODS ____
-(void)fillSpectrumWithTestCoordinates
{
    srand((UInt)time(NULL));
    for(UInt i = 0, maxnum = 0; i < 2*mScale.h; ++i) {
        if(i>=mScale.h) {
            UInt j = i % mScale.h;
            mSpectrum[j] /=  maxnum; // normalized over [0,1]
            continue;
        }
        
        mSpectrum[i] = rand();
        maxnum = max(mSpectrum[i], maxnum);
    }
}

@end
