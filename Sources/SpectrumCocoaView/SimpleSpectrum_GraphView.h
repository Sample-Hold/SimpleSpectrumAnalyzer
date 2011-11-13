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

@interface SimpleSpectrum_GraphView : NSOpenGLView
{
    Float32 * mSpectrum;
    Point mScale;
}

-(void)resetScale:(Point)scale;
-(void)fillSpectrumWithTestCoordinates;

@end
