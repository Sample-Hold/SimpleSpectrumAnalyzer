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
	kAudioUnitProperty_SpectrumGraphData = 65536
};

struct SpectrumGraphData
{		
    Float64     mSamplingRate;
    Float32		mMax;
    Float32		mMin;
    
    SInt32		mNumBins;
    Float32*     mMagnitudes;
};
typedef struct SpectrumGraphData SpectrumGraphData;


// TODO remove once UI is done
struct FrequencyResponse
{
	Float64		mFrequency;
	Float64		mMagnitude;
};
typedef struct FrequencyResponse FrequencyResponse;



#endif
