//
//  SimpleSpectrum_TestUIAppDelegate.h
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 12/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#include "SimpleSpectrum_TestUIWindow.h"

@interface SimpleSpectrum_TestUIAppDelegate : NSObject <NSApplicationDelegate>
{ 
    SimpleSpectrum_TestUIWindow * mWindow;
}

@property(assign) IBOutlet SimpleSpectrum_TestUIWindow * window;

@end