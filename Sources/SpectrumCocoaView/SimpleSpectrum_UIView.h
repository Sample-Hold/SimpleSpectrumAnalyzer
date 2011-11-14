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
    IBOutlet NSMenu * blockSizeMenu;
    IBOutlet NSMenu * channelSelectMenu;
    IBOutlet NSMenu * windowMenu;
    
    AudioUnit mAU;
    AUEventListenerRef mAUEventListener;    
}

-(IBAction) blockSizeChanged:(id)sender;
-(IBAction) channelSelectChanged:(id)sender;
-(IBAction) windowChanged:(id)sender;

-(void)setAU:(AudioUnit)inAU;

-(void)synchronizeUIWithParameterValues;

void dispatchAudioUnitEventProc(void * inUserData, 
                                void * inObject,
                                AudioUnitEvent const * inEvent,
                                UInt64 inEventHostTime,
                                AudioUnitParameterValue inParameterValue);

-(void)dispatchAudioUnitEvent:(AudioUnitEvent const *)inAUEvent 
                            hostTime:(UInt64) inHostTime
                            value:(Float32) inValue;

-(void)activateMenuItem:(NSMenuItem const *)item;

-(void)activateMenuItemByTag:(NSInteger)tag
                      onMenu:(NSMenu const *)menu;

@end

