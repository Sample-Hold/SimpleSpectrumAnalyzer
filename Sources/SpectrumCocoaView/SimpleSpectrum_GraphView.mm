//
//  SimpleSpectrum_GraphView.m
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrum_GraphView.h"

@implementation SimpleSpectrum_GraphView

#define kDefaultMinHertz	12.
#define kDefaultMaxHertz	22050.
#define kDefaultMinDbFS     -72.
#define kLogBase            2
#define kLogBaseDb          10
#define kNumFreqLines		11
#define kNumDBLines         4
#define kDBAxisGap			35
#define kFreqAxisGap		17
#define kRightMargin		10
#define kTopMargin			8

#pragma mark ____ (INIT /) DEALLOC ____
-(id)initWithFrame:(NSRect)frameRect
{
    if(self = [super initWithFrame:frameRect]) {
        mActiveWidth = frameRect.size.width - kRightMargin - kDBAxisGap;
        mActiveHeight = frameRect.size.height - kTopMargin - kFreqAxisGap;

		// Initialize the text attributes for the db and frequency axis
		NSMutableParagraphStyle *dbLabelStyle = [[NSMutableParagraphStyle alloc] init];
		[dbLabelStyle setParagraphStyle: [NSParagraphStyle defaultParagraphStyle]];
		[dbLabelStyle setAlignment:NSRightTextAlignment];
		
		mDBAxisStringAttributes = 
        [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize: 9], 
          NSFontAttributeName, [dbLabelStyle autorelease], NSParagraphStyleAttributeName,
          [NSColor colorWithDeviceWhite: .1 alpha: 1], 
          NSForegroundColorAttributeName, nil] retain];
		
		NSMutableParagraphStyle *freqLabelStyle = [[NSMutableParagraphStyle alloc] init];
		[freqLabelStyle setParagraphStyle: [NSParagraphStyle defaultParagraphStyle]];
		[freqLabelStyle setAlignment:NSCenterTextAlignment];
		
		mFreqAxisStringAttributes = 
        [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize: 9], 
          NSFontAttributeName, [freqLabelStyle autorelease], NSParagraphStyleAttributeName,
          [NSColor colorWithDeviceWhite: .1 alpha: 1], 
          NSForegroundColorAttributeName, nil] retain];

        [self setPostsFrameChangedNotifications:YES];
    }
    
    return self;
}

-(void)dealloc
{
    [mDBAxisStringAttributes release];
	[mFreqAxisStringAttributes release];
	[mCurvePath release];
	[curveColor release];
	
	[mBackgroundCache release];

    [super dealloc];
}

#pragma mark ____ INTERNAL METHODS ____
double logValueForNumber(double number, double base) 
{
	return log (number) / log(base);
}

- (double) locationForFrequencyValue: (double) value 
{
	if(value >= kDefaultMaxHertz)
        return mActiveWidth;
    if(value <= kDefaultMinHertz)
        return 0;
    
    return floor(value * mActiveWidth / (kDefaultMaxHertz - kDefaultMinHertz)) + .5;
}

- (double) freqValueForLocation: (double) location 
{
	return kDefaultMinHertz + (location * (kDefaultMaxHertz - kDefaultMinHertz) / mActiveWidth);
}

- (double) freqValueAtGridIndex: (UInt32) index 
{
    double location = index * mActiveWidth / kNumFreqLines;
    
    return [self freqValueForLocation:location];
}

- (double) locationForDBValue: (double) value 
{
	if(value <= kDefaultMinDbFS)
        return mActiveHeight;
    
    return floor(value * mActiveHeight / kDefaultMinDbFS) + .5;
}

- (double) dbValueForLocation: (double) location 
{
	return location * kDefaultMinDbFS / mActiveHeight;
}

- (double) dbValueAtGridIndex: (UInt32) index 
{
    double location = index * mActiveHeight / kNumDBLines;
    
    return [self dbValueForLocation:location];
}

- (NSString *) stringForValue:(double) value 
{		
	NSString * theString;
	double temp = value;
	
	if (value >= 1000)
		temp = temp / 1000;
	
	temp = (floor(temp *10))/10;	// chop everything after 1 decimal place

	//if we do not have trailing zeros
	if (floor(temp) == temp)
		theString = [NSString localizedStringWithFormat: @"%1.0f", temp];
	else 	// if we have only one digit
		theString = [NSString localizedStringWithFormat: @"%1.1f", temp];
	
	return theString;
}

- (void)drawDBGridLines {
	[[NSColor whiteColor] set];
    
	for (UInt32 index = 0; index <= kNumDBLines; ++index) {
        double value = [self dbValueAtGridIndex:index];
        double location = [self locationForDBValue:value];
        
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0, location) toPoint: NSMakePoint(mActiveWidth, location)];
	}
}

- (void)drawDBLabels {
    float labelWidth = kDBAxisGap - 4;

	for (UInt32 index = 1; index <= kNumDBLines; ++index) {
        double value = [self dbValueAtGridIndex:index];
        double location = [self locationForDBValue:value];

        [[[self stringForValue: value] stringByAppendingString: @"db"] 
         drawInRect: NSMakeRect(0, -location - 3, labelWidth, 11) 
         withAttributes: mDBAxisStringAttributes];
	}
}

- (void) drawFreqGridLines {
	[[[NSColor redColor] colorWithAlphaComponent: .15] set];
    
	for (UInt32 index = 0; index <= kNumFreqLines; ++index) {
        double value = [self freqValueAtGridIndex:index];
		double location = [self locationForFrequencyValue: value];
		
        [NSBezierPath strokeLineFromPoint:NSMakePoint(location, 2) toPoint:NSMakePoint(location, mActiveHeight - 2)];
	}
}

- (void) drawFreqLabels {
    UInt32 labelWidth = 30;
	BOOL firstK = YES;	// we only want a 'K' label the first time a value is over 1000
    
	for (UInt32 index = 0; index <= kNumFreqLines; ++index) {
        double value = [self freqValueAtGridIndex:index];
		double location = [self locationForFrequencyValue: value];
		
		if (index > 0 && index < kNumFreqLines) {	
			NSString *s = [self stringForValue: value];
            
			if (value >= 1000 && firstK) {
				s = [s stringByAppendingString: @"K"];
				firstK = NO;
			}

			[s drawInRect: NSMakeRect(location - labelWidth/5, 0, labelWidth, 11) 
                withAttributes: mFreqAxisStringAttributes];
		} else if (index == 0) {	// append hertz label to first frequency
			[[[self stringForValue: value] stringByAppendingString: @"Hz"] 
                drawInRect: NSMakeRect(location, 0, labelWidth, 11) 
                withAttributes: mFreqAxisStringAttributes];
		} else {	// always label the last grid marker the maximum hertz value
			[[[self stringForValue: kDefaultMaxHertz] stringByAppendingString: @"K"] 
                drawInRect: NSMakeRect(location-labelWidth/2, 0, labelWidth, 11) 
                withAttributes: mFreqAxisStringAttributes];
		}
	}
}

#pragma mark ____ PUBLIC METHODS ____
-(BOOL)isOpaque
{
    return YES;
}

- (void)drawRect:(NSRect)rect
{
	if (!mBackgroundCache) {
		mBackgroundCache = [[NSImage alloc] initWithSize: rect.size];

		[mBackgroundCache lockFocus];
        
        NSAffineTransform * transform = [NSAffineTransform transform];
        
        [transform translateXBy:kDBAxisGap yBy: mActiveHeight + kTopMargin];
        [transform scaleXBy:1.0 yBy:-1.0];
        [transform concat];
        
		// fill the graph area
		[[NSColor colorWithDeviceWhite: .90 alpha: 1.0] set];
		NSRectFill(NSIntersectionRect(rect, NSMakeRect(0, 0, mActiveWidth, mActiveHeight)));
		
		// draw the graph border
		[[NSColor whiteColor] set];
		NSRect lineRect = NSMakeRect(0, 0, mActiveWidth, 1);
		NSRectFill(NSIntersectionRect(rect, lineRect));
		
		[[NSColor colorWithDeviceWhite: .46 alpha: 1] set];
		lineRect.origin.y += 1;
		NSRectFill(NSIntersectionRect(rect, lineRect));
		
		[[NSColor colorWithDeviceWhite: .75 alpha: 1] set];
		lineRect.origin.y += 1;
		NSRectFill(NSIntersectionRect(rect, lineRect));
        
		[self drawDBGridLines];
		[self drawFreqGridLines];
        
        [transform invert];
        [transform translateXBy: kDBAxisGap - kRightMargin yBy: mActiveHeight + kTopMargin];
        [transform concat];
        
        [self drawFreqLabels];

        [transform invert];
        [transform scaleXBy:1.0 yBy:-1.0];
        [transform translateXBy:-kDBAxisGap yBy:0.0];
        [transform concat];
        
        [self drawDBLabels];
        
        [transform invert];
        [transform translateXBy:-kDBAxisGap + kRightMargin yBy: -mActiveHeight-kTopMargin];
        [transform concat];

		[mBackgroundCache unlockFocus];
	}
    
    [[NSColor controlColor] set];
    NSRectFill(rect);
    
    [mBackgroundCache drawInRect: rect fromRect: rect operation: NSCompositeSourceOver fraction: 1.0];
    
	if (curveColor) {
		[curveColor set]; 
        
        NSAffineTransform * transform = [NSAffineTransform transform];
        [transform translateXBy: kDBAxisGap + 1 yBy: mActiveHeight + kTopMargin + 1];
        [transform scaleXBy:1.0 yBy:-1.0];
        [transform concat];
        
		[mCurvePath fill];
	}
}

-(void) setFrameSize: (NSSize) newSize {	
    mActiveWidth = newSize.width - kRightMargin - kDBAxisGap;
    mActiveHeight = newSize.height - kTopMargin - kFreqAxisGap;
	
	[mBackgroundCache release];
	mBackgroundCache = nil;
    
	[super setFrameSize: newSize];
}

-(void) setFrame: (NSRect) frameRect {
    [self setFrameSize:frameRect.size];	
}

-(void) plotData: (Float32 *) data givenInfos: (SpectrumGraphInfo) infos;
{	
	if (!curveColor)
		curveColor = [[NSColor colorWithDeviceRed: .31 green: .37 blue: .73 alpha: .8] retain];
    
	[mCurvePath release];
	mCurvePath = [[NSBezierPath bezierPath] retain];
    
    Float32 lastDBPos = [self locationForDBValue: kDefaultMinDbFS];
	[mCurvePath moveToPoint:NSMakePoint(0, lastDBPos)];
    
	for (UInt32 i = 0; i < infos.mNumBins; ++i) {		
		Float32 freq = (Float32)i * infos.mSamplingRate / (Float32)(infos.mNumBins * 2);
        Float32 dbValue = data[i];
		Float32 dbPos = 0;												
		if (dbValue < kDefaultMinDbFS)
			dbPos = [self locationForDBValue: kDefaultMinDbFS];
		else if (dbValue > 0)
			dbPos = 0;
		else 
			dbPos = [self locationForDBValue: dbValue];	
		
        // only create a new point in our bezier path if the current db pixel value
		if (fabsf(lastDBPos - dbPos) >= .1)								 
			[mCurvePath lineToPoint: NSMakePoint([self locationForFrequencyValue:freq], dbPos)];	
                                                 
		lastDBPos = dbPos;
    }

	[mCurvePath closePath];
	
	[self setNeedsDisplay: YES];	
}

-(void) disableGraphCurve {													
    // update the view, but don't draw the curve (used when the AU is not initialized and the curve can not be retrieved)
	if (curveColor) {
		[curveColor release];
		curveColor = nil;
	}
	[self setNeedsDisplay: YES];
}

@end
