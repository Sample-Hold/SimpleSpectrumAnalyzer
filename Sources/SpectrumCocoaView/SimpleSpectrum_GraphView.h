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
	Float32 mActiveWidth, mActiveHeight;
	NSColor *curveColor;
	NSImage *mBackgroundCache;
	NSBezierPath *mCurvePath;		
	NSDictionary *mDBAxisStringAttributes, *mFreqAxisStringAttributes;	
}

-(CGFloat) locationForFrequencyValue: (double) value;
-(CGFloat) locationForDBValue: (Float32) value;
-(CGFloat) locationForDBGridIndex: (UInt32) index;

-(double) freqValueAtGridIndex: (UInt32) index;
-(Float32) dbValueAtGridIndex: (UInt32) index;

-(NSString *) stringForValue:(double) value withDecimal:(BOOL) setDecimal;

-(void) plotData:(Float32 *) data givenInfos:(SpectrumGraphInfo) infos;
-(void) disableGraphCurve;

@end
