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
	Float32 mActiveWidth;
    Float32 mActiveHeight;
	NSColor * curveColor;
	NSImage * mBackgroundCache;
	NSBezierPath * mCurvePath;		
	NSDictionary * mDBAxisStringAttributes;		
    NSDictionary * mFreqAxisStringAttributes;	
}

double logValueForNumber(double number, double base);

- (double) locationForFrequencyValue: (double) value;
- (double) freqValueForLocation: (double) location;
- (double) freqValueAtGridIndex: (UInt32) index;
- (double) locationForDBValue: (double) value;
- (double) dbValueForLocation: (double) location;
- (double) dbValueAtGridIndex: (UInt32) index;

-(void) plotData: (Float32 *) data givenInfos: (SpectrumGraphInfo) infos;
-(void) disableGraphCurve;

@end
