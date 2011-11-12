//
//  SimpleSpectrum_ViewFactory.h
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrum_UIView.h"

@interface SimpleSpectrum_ViewFactory : NSObject<AUCocoaUIBase>
{
    IBOutlet SimpleSpectrum_UIView *uiFreshlyLoadedView;
}

-(NSString *) description;
@end
