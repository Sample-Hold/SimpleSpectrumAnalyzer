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
    NSRect	mGraphFrame;
	float	mActiveWidth;
	NSColor * curveColor;
	NSImage * mBackgroundCache;
	NSBezierPath * mCurvePath;		
	NSDictionary * mDBAxisStringAttributes;		
    NSDictionary * mFreqAxisStringAttributes;	
}

-(double) locationForFrequencyValue: (double) value;	
-(double) locationForDBValue: (double) value;	

-(SpectrumGraphData *) prepareDataForDrawing: (SpectrumGraphData *) data;
-(void) plotData: (SpectrumGraphData *) data;
-(void) disableGraphCurve;

@end
