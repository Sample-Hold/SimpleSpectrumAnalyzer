//
//  SimpleSpectrum_UIView.m
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrum_UIView.h"

@implementation SimpleSpectrum_UIView

#pragma mark ____ (INIT /) DEALLOC ____
-(void)dealloc 
{
    [self performSelector:@selector(unregisterEventListener:) withObject:self];
    mAU = nil;
    
    [super dealloc];
}

#pragma mark ____ INTERFACE ACTIONS ____
-(void)blockSizeChanged:(id)sender
{
    NSMenuItem * item = (NSMenuItem*) sender;
    NSInteger tag = [item tag];
    
    if (!mAU)
        return;
    
	AudioUnitParameter blockSizeParameter = {mAU, kSpectrumParam_BlockSize, kAudioUnitScope_Global, 0 };
	
	NSAssert(AUParameterSet(mAUEventListener, sender, &blockSizeParameter, (Float32) tag, 0) == noErr,
             @"[SimpleSpectrum_UIView blockSizeChanged:] AUParameterSet()");
}

-(void)channelSelectChanged:(id)sender
{
    NSMenuItem * item = (NSMenuItem*) sender;
    NSInteger tag = [item tag];
    
    if (!mAU)
        return;
    
	AudioUnitParameter channelParameter = {mAU, kSpectrumParam_SelectChannel, kAudioUnitScope_Global, 0 };
	
	NSAssert(AUParameterSet(mAUEventListener, sender, &channelParameter, (Float32) tag, 0) == noErr,
             @"[SimpleSpectrum_UIView channelsChanged:] AUParameterSet()");
}

-(void)windowChanged:(id)sender
{
    NSMenuItem * item = (NSMenuItem*) sender;
    NSInteger tag = [item tag];
    
    if (!mAU)
        return;
    
	AudioUnitParameter windowParameter = {mAU, kSpectrumParam_Window, kAudioUnitScope_Global, 0 };
	
	NSAssert(AUParameterSet(mAUEventListener, sender, &windowParameter, (Float32) tag, 0) == noErr,
             @"[SimpleSpectrum_UIView windowChanged:] AUParameterSet()");
}

#pragma mark ____ PUBLIC METHODS ____
-(void)setAU:(AudioUnit)inAU {
	if (mAU) {
        // remove previous register
        [self performSelector:@selector(unregisterEventListener:) withObject:self];
    }
	
	mAU = inAU;
    
	// add new listeners
	[self performSelector:@selector(registerEventListener:) withObject:self];
    
    // synchronize UI parameters
    [self synchronizeUIWithParameterValues];
    
    // check numbers of channels
    [self performSelector:@selector(checkNumChannels:) withObject:self];
}

- (void)synchronizeUIWithParameterValues {
    Float32 inValue;
    
	NSAssert (	AudioUnitGetParameter(mAU, kSpectrumParam_BlockSize, kAudioUnitScope_Global, 0, &inValue) == noErr,
              @"[SimpleSpectrum_UIView synchronizeUIWithParameterValues]");
    
    [self activateMenuItemByTag:(NSInteger)inValue onMenu:blockSizeMenu];
    
	NSAssert (	AudioUnitGetParameter(mAU, kSpectrumParam_SelectChannel, kAudioUnitScope_Global, 0, &inValue) == noErr,
              @"[SimpleSpectrum_UIView synchronizeUIWithParameterValues]");
    
    [self activateMenuItemByTag:(NSInteger)inValue onMenu:channelSelectMenu];
	
	NSAssert (	AudioUnitGetParameter(mAU, kSpectrumParam_Window, kAudioUnitScope_Global, 0, &inValue) == noErr,
              @"[SimpleSpectrum_UIView synchronizeUIWithParameterValues]");
    
    [self activateMenuItemByTag:(NSInteger)inValue onMenu:windowMenu];
}

void dispatchAudioUnitEventProc(void * inUserData, 
                                void * inObject,
                                AudioUnitEvent const * inEvent,
                                UInt64 inEventHostTime,
                                AudioUnitParameterValue inParameterValue) 
{
    SimpleSpectrum_UIView * refView = (SimpleSpectrum_UIView *) inUserData;
    
    [refView dispatchAudioUnitEvent:inEvent hostTime:inEventHostTime value:inParameterValue];
}

-(void)dispatchAudioUnitEvent:(AudioUnitEvent const *)inAUEvent 
                    hostTime:(UInt64)inHostTime 
                    value:(AudioUnitParameterValue)inValue
{
    switch (inAUEvent->mEventType) {
		case kAudioUnitEvent_ParameterValueChange:
		{	
            switch (inAUEvent->mArgument.mParameter.mParameterID) {
				case kSpectrumParam_BlockSize:
                {                        
                    [self activateMenuItemByTag:(NSInteger)inValue onMenu:blockSizeMenu];
                    
					break;
				}
                case kSpectrumParam_SelectChannel:
                {
                    [self activateMenuItemByTag:(NSInteger)inValue onMenu:channelSelectMenu];
                    break;
                }
                case kSpectrumParam_Window:
                {
                    [self activateMenuItemByTag:(NSInteger)inValue onMenu:windowMenu];
                    break;
                }
			}
			break;
        }
        case kAudioUnitEvent_PropertyChange:
        {
            switch (inAUEvent->mArgument.mProperty.mPropertyID) {
                case kAudioUnitProperty_SpectrumGraphData:
                    [self performSelector:@selector(drawSpectrumGraph:) withObject:self];
                    break;
                case kAudioUnitProperty_SpectrumGraphInfo:
                    [self performSelector:@selector(checkNumChannels:) withObject:self];
                    break;
                    
            }
        }
    }
}

-(void)activateMenuItem:(NSMenuItem const *)item
{
    for(NSMenuItem * otherItem in [[item menu] itemArray])
        if(otherItem != item)
            [otherItem setState:NSOffState];
    
    [item setState:NSOnState];
}

-(void)activateMenuItemByTag:(NSInteger)tag 
                      onMenu:(const NSMenu *)menu
{
    NSMenuItem * item = [menu itemWithTag:tag];
    [self activateMenuItem:item];
}

-(void)disableMenu:(NSMenu const *)menu
                    andFlagMenuItemWithTag:(NSInteger)tag
{
    for(NSMenuItem * item in [menu itemArray]) {
        [item setState:[item tag] == tag ? NSMixedState : NSOffState];
        [item setHidden:[item tag] == tag ? NO : YES];
        [item setEnabled:NO];
    }
}

#pragma mark ____ INTERNAL METHODS ____
- (void)registerEventListener:(id)sender
{
    if (!mAU)
        return;
    
	verify_noerr( AUEventListenerCreate(dispatchAudioUnitEventProc, 
                                        sender,
                                        CFRunLoopGetCurrent(), 
                                        kCFRunLoopDefaultMode, 0.05, 0.05, 
                                        &mAUEventListener));
		
    AudioUnitEvent auEvent;
    auEvent.mEventType = kAudioUnitEvent_ParameterValueChange;
    AudioUnitParameter parameter = 
            {mAU, kSpectrumParam_BlockSize, kAudioUnitScope_Global, 0 };
    auEvent.mArgument.mParameter = parameter;
	verify_noerr (AUEventListenerAddEventType(mAUEventListener, self, &auEvent));
		
    auEvent.mArgument.mParameter.mParameterID = kSpectrumParam_SelectChannel;
    verify_noerr (AUEventListenerAddEventType(mAUEventListener, self, &auEvent));
    
    auEvent.mArgument.mParameter.mParameterID = kSpectrumParam_Window;
    verify_noerr (AUEventListenerAddEventType(mAUEventListener, self, &auEvent));
				
    auEvent.mEventType = kAudioUnitEvent_PropertyChange;
    auEvent.mArgument.mProperty.mAudioUnit = mAU;
    auEvent.mArgument.mProperty.mPropertyID = kAudioUnitProperty_SpectrumGraphData;
    auEvent.mArgument.mProperty.mScope = kAudioUnitScope_Global;
    auEvent.mArgument.mProperty.mElement = 0;		
    verify_noerr (AUEventListenerAddEventType (mAUEventListener, self, &auEvent)); 
    
    auEvent.mArgument.mProperty.mPropertyID = kAudioUnitProperty_SpectrumGraphInfo;
    verify_noerr (AUEventListenerAddEventType (mAUEventListener, self, &auEvent)); 
}

- (void)unregisterEventListener:(id)sender
{
	if (mAUEventListener) verify_noerr (AUListenerDispose(mAUEventListener));
	mAUEventListener = nil;
}

-(void)drawSpectrumGraph:(id)sender
{    
    SpectrumGraphInfo graphInfo;
    graphInfo.mNumBins = 0;
    
    UInt32 sizeOfResult = sizeof(graphInfo);
    
    ComponentResult result = AudioUnitGetProperty(mAU,
                                                  kAudioUnitProperty_SpectrumGraphInfo,
                                                  kAudioUnitScope_Global,
                                                  0,
                                                  &graphInfo,
                                                  &sizeOfResult);
    
    if(result == noErr && graphInfo.mNumBins > 0) {
        CAAutoFree<Float32> graphData;
        graphData.allocBytes(sizeOfResult = graphInfo.mNumBins * sizeof(Float32));
        
        result = AudioUnitGetProperty(mAU,
                                      kAudioUnitProperty_SpectrumGraphData,
                                      kAudioUnitScope_Global,
                                      0,
                                      graphData(),
                                      &sizeOfResult);
        
        [graphView plotData: graphData givenInfos: graphInfo];
    }
}

-(void)checkNumChannels:(id)sender
{
    SpectrumGraphInfo graphInfo;
    
    UInt32 sizeOfResult = sizeof(graphInfo);
    
    ComponentResult result = AudioUnitGetProperty(mAU,
                                                  kAudioUnitProperty_SpectrumGraphInfo,
                                                  kAudioUnitScope_Global,
                                                  0,
                                                  &graphInfo,
                                                  &sizeOfResult);
    
    if(result == noErr && graphInfo.mNumChannels == 1) {
        [self disableMenu:channelSelectMenu andFlagMenuItemWithTag:1];
    }
}

@end
