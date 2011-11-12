//
//  SimpleSpectrum_GraphView.h
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrumSharedData.h"

#define BITS_PER_PIXEL          32.0
#define DEPTH_SIZE              32.0
#define DEFAULT_TIME_INTERVAL   0.001

@interface SimpleSpectrum_GraphView : NSOpenGLView
{
    float * testCoordinates;
    unsigned testSize;
    
    NSTimer  *time;
}

void fillWithTestCoordinates(float * output, unsigned outputSize);

@end
