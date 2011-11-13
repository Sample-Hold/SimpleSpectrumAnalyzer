//
//  SimpleSpectrum_UIView.m
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrum_UIView.h"

@implementation SimpleSpectrum_UIView

@synthesize AU = mAU;

#pragma mark ____ (INIT /) DEALLOC ____
-(id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
        [self performSelector:@selector(registerEventListener:) withObject:self];
    
    return self;
}

-(void)dealloc 
{
    [self performSelector:@selector(unregisterEventListener:) withObject:self];
    
    [super dealloc];
}

#pragma mark ____ PUBLIC METHODS ____
void dispatchAudioUnitEventProc(void * inUserData, 
                                void * inObject,
                                AudioUnitEvent const * inEvent,
                                UInt64 inEventHostTime,
                                AudioUnitParameterValue inParameterValue) 
{
    SimpleSpectrum_UIView * refView = (SimpleSpectrum_UIView *) inUserData;
    
    [refView dispatchAudioUnitEvent:*inEvent hostTime:inEventHostTime value:inParameterValue];
}

-(void)dispatchAudioUnitEvent:(AudioUnitEvent)inAUEvent 
                    hostTime:(UInt64)inHostTime 
                    value:(Float32)inValue
{
    // TODO dispatch events
}

#pragma mark ____ INTERNAL METHODS ____
- (void)registerEventListener:(id)sender
{
    verify_noerr( AUEventListenerCreate(dispatchAudioUnitEventProc, 
                                        sender,
                                        CFRunLoopGetCurrent(), 
                                        kCFRunLoopDefaultMode, 0.05, 0.05, 
                                        &mAUEventListener));
}

- (void)unregisterEventListener:(id)sender
{
	if (mAUEventListener) verify_noerr (AUListenerDispose(mAUEventListener));
	mAUEventListener = NULL;
}

@end
