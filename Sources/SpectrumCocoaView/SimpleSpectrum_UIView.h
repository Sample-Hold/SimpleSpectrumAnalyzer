//
//  SimpleSpectrum_UIView.h
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrum_GraphView.h"

@interface SimpleSpectrum_UIView : NSView
{
    IBOutlet SimpleSpectrum_GraphView * graphView;

    AudioUnit mAU;
    AUEventListenerRef mAUEventListener;    
}

@property AudioUnit AU;

void dispatchAudioUnitEventProc(void * inUserData, 
                                void * inObject,
                                AudioUnitEvent const * inEvent,
                                UInt64 inEventHostTime,
                                AudioUnitParameterValue inParameterValue);

-(void)dispatchAudioUnitEvent:(AudioUnitEvent) inAUEvent
                            hostTime:(UInt64) inHostTime
                            value:(Float32) inValue;


@end

