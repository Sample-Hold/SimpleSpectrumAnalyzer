//
//  SpectrumParameters.h
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 07/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifndef SimpleSprectrumAnalyzer_SpectrumSharedData_h
#define SimpleSprectrumAnalyzer_SpectrumSharedData_h

enum
{
	kSpectrumParam_BlockSize = 0,
	kSpectrumParam_SelectChannel = 1,
    kSpectrumParam_Window = 2
};

typedef UInt64 SampleTime;

struct SpectrumGraphData
{
    AudioTimeStamp	mFetchStamp;	// the view writes
	
	UInt32			mNumBins;		// the au writes
	
	Float32			mMaxAmp;		// the au writes
	Float32			mMinAmp;		// the au writes
    
    Float32			mData[1];	// the au writes  
};
typedef struct SpectrumGraphData SpectrumGraphData;



struct FrequencyResponse
{
	Float64		mFrequency;
	Float64		mMagnitude;
};
typedef struct FrequencyResponse FrequencyResponse;



#endif
