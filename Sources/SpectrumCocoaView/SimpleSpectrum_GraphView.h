//
//  SimpleSpectrum_GraphView.h
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrumSharedData.h"

@interface SimpleSpectrum_GraphView : NSView
{
    IBOutlet NSTextField * cursorInfos;
    
	Float32 mActiveWidth, mActiveHeight;
	NSColor *curveColor;
	NSImage *mBackgroundCache;
	NSBezierPath *mCurvePath;		
	NSDictionary *mDBAxisStringAttributes, *mFreqAxisStringAttributes;	
    NSTrackingRectTag mMouseTrackingRect;
    BOOL mWasAcceptingMouseEvents, mDisplayCursorInfos;
}

-(CGFloat) locationForFrequencyValue: (double) value;
-(double) freqValueAtLocation: (CGFloat) location;
-(double) freqValueAtGridIndex: (CGFloat) index;

-(CGFloat) locationForDBGridIndex: (CGFloat) index;
-(CGFloat) locationForDBValue: (Float32) value;
-(Float32) dbValueAtLocation: (CGFloat) location;
-(Float32) dbValueAtGridIndex: (CGFloat) index;

-(NSString *) stringForValue:(double)value 
             divideThousands:(BOOL)divide 
                showDecimals:(BOOL)decimals;

-(void) plotData:(Float32 *) data givenInfos:(SpectrumGraphInfo) infos;
-(void) disableGraphCurve;

@end
