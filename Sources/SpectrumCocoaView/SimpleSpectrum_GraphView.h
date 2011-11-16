//
//  SimpleSpectrum_GraphView.h
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrumSharedData.h"

#define DEFAULT_HSCALE          512
#define DEFAULT_VSCALE          256

@interface SimpleSpectrum_GraphView : NSView
{
    Float32 * mSpectrum;
    Point mScale;
    
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

-(FrequencyResponse *) prepareDataForDrawing: (FrequencyResponse *) data;	// prepares the data for drawing by initializing frequency fields based on values on pixel boundaries
-(void) plotData: (FrequencyResponse *) data;								// draws the curve data
-(void) disableGraphCurve;													// update the view, but don't draw the curve (used when the AU is not initialized and the curve can not be retrieved)

-(void)resetScale:(Point)scale;
-(void)fillSpectrumWithTestCoordinates;

@end
