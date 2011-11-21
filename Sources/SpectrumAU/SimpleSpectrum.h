//
//  Spectrum.h
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifndef SimpleSprectrumAnalyzer_Spectrum_h
#define SimpleSprectrumAnalyzer_Spectrum_h

#include "SimpleSpectrumVersion.h"
#include "SimpleSpectrumSharedData.h"
#include "SimpleSpectrumProcessor.h"

#include "CAMutex.h"

#pragma mark SimpleSpectrumKernel
class SimpleSpectrumKernel : public AUKernelBase
{
public:
	SimpleSpectrumKernel(AUEffectBase *inAudioUnit );
    
    // processes one channel of non-interleaved samples
	virtual void Process(Float32 const* inSourceP,
                         Float32 * inDestP,
                         UInt32 inFramesToProcess,
                         UInt32 inNumChannels,
                         bool & ioSilence);
};

#pragma mark SimpleSpectrum
class SimpleSpectrum : public AUEffectBase
{ 
    SimpleSpectrumProcessor mProcessor;
    SpectrumGraphInfo mInfos;
    CAAutoFree<Float32> mComputedMagnitudes;
    CAMutex mCAMutex;
public:
	SimpleSpectrum(AudioUnit component);

	virtual OSStatus Version() { return kSpectrumAnalyzerVersion; }
	virtual OSStatus Initialize();

	virtual AUKernelBase * NewKernel() { return new SimpleSpectrumKernel(this); }
    virtual OSStatus Render(AudioUnitRenderActionFlags & ioActionFlags,
                    const AudioTimeStamp & inTimeStamp,
                    UInt32 inFramesToProcess );
    
	virtual OSStatus GetProperty(AudioUnitPropertyID inID,
                                 AudioUnitScope inScope,
                                 AudioUnitElement inElement,
                                 void * outData );
    virtual OSStatus GetPropertyInfo(AudioUnitPropertyID inID,
                                     AudioUnitScope inScope,
                                     AudioUnitElement inElement,
                                     UInt32 & outDataSize,
                                     Boolean & outWritable );
	virtual OSStatus GetParameterInfo(AudioUnitScope inScope,
                                      AudioUnitParameterID inParameterID,
                                      AudioUnitParameterInfo & outParameterInfo );
    virtual OSStatus GetParameterValueStrings(AudioUnitScope inScope, 
                                              AudioUnitParameterID inParameterID, 
                                              CFArrayRef * outStrings);
	
    // no tail
	virtual	bool				SupportsTail() { return false; }
	// no latency
    virtual Float64				GetLatency() {return 0.0; }
};

AUDIOCOMPONENT_ENTRY(AUBaseFactory, SimpleSpectrum)

#pragma mark Parameters
static CFStringRef kBlockSize_Name = CFSTR("Block");
static CFStringRef kSelectChannel_Name = CFSTR("Channel");
static CFStringRef kWindow_Name = CFSTR("Window");

const ShortFixed kBlockSize_Option1 = 1;
const ShortFixed kBlockSize_Option2 = 2;
const ShortFixed kBlockSize_Option3 = 3;
const ShortFixed kBlockSize_Option4 = 4;
const ShortFixed kBlockSize_Option5 = 5;

const ShortFixed kBlockSize_Default = kBlockSize_Option1;

static CFStringRef kBlockSize_Option1_Name = CFSTR ("1024");
static CFStringRef kBlockSize_Option2_Name = CFSTR ("2048");
static CFStringRef kBlockSize_Option3_Name = CFSTR ("4096");
static CFStringRef kBlockSize_Option4_Name = CFSTR ("8192");
static CFStringRef kBlockSize_Option5_Name = CFSTR ("16384");

const ShortFixed kSelectChannel_Left = 1;  
const ShortFixed kSelectChannel_Right = 2; 
const ShortFixed kSelectChannel_Both = 3;

const ShortFixed kSelectChannel_Default = kSelectChannel_Left;

static CFStringRef kSelectChannel_Left_Name = CFSTR ("Left");
static CFStringRef kSelectChannel_Right_Name = CFSTR ("Right");
static CFStringRef kSelectChannel_Both_Name = CFSTR ("Both");

const ShortFixed kWindow_Rectangular = 1;
const ShortFixed kWindow_Hann = 2;
const ShortFixed kWindow_Hamming = 3;
const ShortFixed kWindow_Blackman = 4;

const ShortFixed kWindow_Default = kWindow_Hann;

static CFStringRef kWindow_Rectangular_Name = CFSTR ("Rectangular");
static CFStringRef kWindow_Hann_Name = CFSTR ("Hann");
static CFStringRef kWindow_Hamming_Name = CFSTR ("Hamming");
static CFStringRef kWindow_Blackman_Name = CFSTR ("Blackman");

#endif
