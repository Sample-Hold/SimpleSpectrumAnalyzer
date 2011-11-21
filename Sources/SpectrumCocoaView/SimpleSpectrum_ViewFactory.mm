//
//  SimpleSpectrum_ViewFactory.m
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrum_ViewFactory.h"

@implementation SimpleSpectrum_ViewFactory

-(unsigned int)interfaceVersion 
{
    return 0;
}

-(NSString *)description 
{
    return @"Simple Spectrum View";
}

-(NSView *)uiViewForAudioUnit:(AudioUnit)inAudioUnit withSize:(NSSize)inPreferredSize 
{
    if(![NSBundle loadNibNamed:@"SpectrumView" owner:self]) 
    { 
        NSLog(@"Unable to load nib from view");
        return nil;
    }
    
    [uiFreshlyLoadedView setAU:inAudioUnit];
    
    NSView *returnView = uiFreshlyLoadedView;
    uiFreshlyLoadedView = nil;	// zero out pointer.  This is a view factory.  Once a view's been created
    // and handed off, the factory keeps no record of it.
    
    return [returnView autorelease];
}

@end
