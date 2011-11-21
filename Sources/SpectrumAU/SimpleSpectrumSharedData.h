//
//  SpectrumParameters.h
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 07/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifndef SimpleSprectrumAnalyzer_SpectrumSharedData_h
#define SimpleSprectrumAnalyzer_SpectrumSharedData_h

#pragma mark ___SimpleSpectrum Parameters
enum
{
	kSpectrumParam_BlockSize = 0,
	kSpectrumParam_SelectChannel = 1,
    kSpectrumParam_Window = 2
};

#pragma mark ___SimpleSpectrum Properties
enum
{
	kAudioUnitProperty_SpectrumGraphInfo = 65536,
    kAudioUnitProperty_SpectrumGraphData = 65537
};

struct SpectrumGraphInfo
{		
    Float64 mSamplingRate;
    SInt32 mNumBins;
};

#endif