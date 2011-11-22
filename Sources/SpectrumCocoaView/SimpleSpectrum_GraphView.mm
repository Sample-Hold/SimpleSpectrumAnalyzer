//
//  SimpleSpectrum_GraphView.m
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrum_GraphView.h"

#import "CABitOperations.h"

#define kDefaultMinHertz	11
#define kDefaultMaxHertz	22050
#define kNumFreqLines		11

#define kDefaultMinDbFS     -72
#define kNumDBLines         4

#define kDBAxisGap			40
#define kFreqAxisGap		17
#define kRightMargin		10
#define kTopMargin			8

@implementation SimpleSpectrum_GraphView
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

#pragma mark ____ PUBLIC METHODS ____
-(CGFloat) locationForFrequencyValue: (double) value 
{
	if(value >= kDefaultMaxHertz)
        return mActiveWidth - 5;
    if(value <= kDefaultMinHertz)
        return .5;
    
    double pixelIncrement = mActiveWidth / (double) kNumFreqLines;
    double normalizedValue = value / kDefaultMinHertz;
	double location = log2(normalizedValue) * pixelIncrement;

	return floor(location) + .5;
}

-(CGFloat) locationForDBValue: (Float32) value 
{
	if(value <= kDefaultMinDbFS)
        return mActiveHeight - .5;
    if(value >= 0)
        return .5;
    
    double normalizedValue = value / (double) kDefaultMinDbFS;
    normalizedValue = -1 * cos(M_PI_2 * normalizedValue)  + 1;
    
    return floor(normalizedValue * mActiveHeight) + .5;
}

-(CGFloat) locationForDBGridIndex: (UInt32) index 
{
    double normalizedIndex = index / (double) kNumDBLines;
    
    return floor(normalizedIndex * mActiveHeight) + .5;
}

-(double) freqValueAtGridIndex: (UInt32) index 
{    
    double freq = kDefaultMinHertz * pow(2, index);
    
    if(freq > kDefaultMaxHertz)
        return kDefaultMaxHertz;

    return floor(freq/10) *10;
}

-(Float32) dbValueAtGridIndex: (UInt32) index 
{
    Float32 normalizedIndex = index / (Float32) kNumDBLines;
    normalizedIndex = -1 * cos(M_PI_2 * normalizedIndex)  + 1;
    
    return normalizedIndex * kDefaultMinDbFS;
}

-(NSString *) stringForValue:(double) value withDecimal:(BOOL)setDecimal
{		
	NSString * theString;
	double temp = value;
	
	if (value >= 1000)
		temp = temp / 1000;
	
	temp = (floor(temp *10))/10;	// chop everything after 1 decimal place

	//if we do not have trailing zeros or don't want decimal
	if (setDecimal == NO || floor(temp) == temp)
		theString = [NSString localizedStringWithFormat: @"%1.0f", temp];
	else 
		theString = [NSString localizedStringWithFormat: @"%1.1f", temp];
	
	return theString;
}

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
        
        // draw grid
        [self performSelector:@selector(drawDBGridLines:)];
        [self performSelector:@selector(drawFreqGridLines:)];
        
        [transform invert];
        [transform translateXBy: kDBAxisGap - kRightMargin yBy: mActiveHeight + kTopMargin];
        [transform concat];
        
        // draw labels
        [self performSelector:@selector(drawFreqLabels:)];

        [transform invert];
        [transform scaleXBy:1.0 yBy:-1.0];
        [transform translateXBy:-kDBAxisGap yBy:0.0];
        [transform concat];
        
        [self performSelector:@selector(drawDBLabels:)];
        
        [transform invert];
        [transform translateXBy:-kDBAxisGap + kRightMargin yBy: -mActiveHeight-kTopMargin];
        [transform concat];

		[mBackgroundCache unlockFocus];
	}
    
    [[NSColor controlColor] set];
    NSRectFill(rect);
    
    [mBackgroundCache drawInRect: rect fromRect: rect operation: NSCompositeSourceOver fraction: 1.0];
    
	if (curveColor) {
        NSAffineTransform * transform = [NSAffineTransform transform];
        [transform translateXBy: kDBAxisGap + 1 yBy: mActiveHeight + kTopMargin + 1];
        [transform scaleXBy:1.0 yBy:-1.0];
        [transform concat];
        
        [curveColor set];
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
    
    CGFloat lastDBPos = [self locationForDBValue: kDefaultMinDbFS], dbPos, distanceX, distanceY;
    NSPoint lastPoint = NSMakePoint(.5, lastDBPos), dest, controlPoint;
	[mCurvePath moveToPoint:lastPoint];
    
	for (UInt32 i = 1; i < infos.mNumBins; ++i) {		
		double freq = i * (double) infos.mSamplingRate / (double)(infos.mNumBins * 2);
        dbPos = [self locationForDBValue: data[i]];												
        
        // only create a new point in our bezier path if db moves by 1 point
        if (lastDBPos - dbPos > 0) {
            dest = NSMakePoint([self locationForFrequencyValue:freq], dbPos);
            
            distanceX = dest.x - lastPoint.x;
            distanceY = dest.y - lastPoint.y;
            
            // smooth curve if distanceX >= 10
            if (distanceX >= 10 && distanceY < 0) // db highering
            {
                controlPoint = NSMakePoint(dest.x, lastPoint.y);
                [mCurvePath curveToPoint: dest controlPoint1: controlPoint controlPoint2: controlPoint];
            }
            else if (distanceX >= 10 && distanceY > 0) // db lowering
            {
                controlPoint = NSMakePoint(lastPoint.x, dest.y);
                [mCurvePath curveToPoint: dest controlPoint1: controlPoint controlPoint2: controlPoint];
            }
            else 
            {
                [mCurvePath lineToPoint:dest];	
            }
            
            lastPoint = dest;
        }
            
		lastDBPos = dbPos;
    }
    
    dest = NSMakePoint(mActiveWidth - .5, [self locationForDBValue: kDefaultMinDbFS]);
    if(dest.x - lastPoint.x >= 10) 
    {
        controlPoint = NSMakePoint(lastPoint.x, dest.y);
        [mCurvePath curveToPoint: dest controlPoint1: controlPoint controlPoint2: controlPoint];    
    }
    else
        [mCurvePath lineToPoint: dest];
	
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

#pragma mark ____ INTERNAL METHODS ____
-(void)drawDBGridLines:(id)sender {
	[[NSColor whiteColor] set];
    
	for (UInt32 index = 0; index <= kNumDBLines; ++index) {
        CGFloat location = [self locationForDBGridIndex:index];
        
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0, location) toPoint: NSMakePoint(mActiveWidth, location)];
	}
}

- (void)drawDBLabels:(id)sender {
    float labelWidth = kDBAxisGap - 4;
    
	for (UInt32 index = 1; index <= kNumDBLines; ++index) {
        Float32 value = [self dbValueAtGridIndex:index];
        CGFloat location = [self locationForDBGridIndex:index];
        
        [[[self stringForValue: value withDecimal:NO] stringByAppendingString: @"db"] 
         drawInRect: NSMakeRect(0, -location - 3, labelWidth, 11) 
         withAttributes: mDBAxisStringAttributes];
	}
}

- (void) drawFreqGridLines:(id)sender {
	[[[NSColor redColor] colorWithAlphaComponent: .15] set];
    
	for (UInt32 index = 0; index <= kNumFreqLines; ++index) {
        double value = [self freqValueAtGridIndex:index];
		CGFloat location = [self locationForFrequencyValue: value];
		
        [NSBezierPath strokeLineFromPoint:NSMakePoint(location, 2) toPoint:NSMakePoint(location, mActiveHeight - 2)];
	}
}

- (void) drawFreqLabels:(id)sender {
    UInt32 labelWidth = kDBAxisGap - 4;
	BOOL firstK = YES;	// we only want a 'K' label the first time a value is over 1000
    
	for (UInt32 index = 0; index <= kNumFreqLines; ++index) {
        double value = [self freqValueAtGridIndex:index];
		CGFloat location = [self locationForFrequencyValue: value];
		
		if (index > 0 && index < kNumFreqLines) {	
			NSString *s = [self stringForValue: value withDecimal: YES];
            
			if (value >= 1000 && firstK) {
				s = [s stringByAppendingString: @"K"];
				firstK = NO;
			}
            
			[s drawInRect: NSMakeRect(location - labelWidth/5, 0, labelWidth, 11) 
           withAttributes: mFreqAxisStringAttributes];
		} else if (index == 0) {	// append hertz label to first frequency
			[[[self stringForValue: value withDecimal: NO] stringByAppendingString: @"Hz"] 
             drawInRect: NSMakeRect(location, 0, labelWidth, 11) 
             withAttributes: mFreqAxisStringAttributes];
		} else {	// always label the last grid marker the maximum hertz value
			[[[self stringForValue: kDefaultMaxHertz withDecimal:NO] stringByAppendingString: @"K"] 
             drawInRect: NSMakeRect(location-labelWidth/2, 0, labelWidth, 11) 
             withAttributes: mFreqAxisStringAttributes];
		}
	}
}

@end