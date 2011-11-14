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

#pragma mark -
class SimpleSpectrumKernel : public AUKernelBase
{
public:
	SimpleSpectrumKernel(AUEffectBase *inAudioUnit );
	virtual ~SimpleSpectrumKernel();
    
	// processes one channel of non-interleaved samples
	virtual void Process(const Float32  *inSourceP,
                         Float32        *inDestP,
                         UInt32         inFramesToProcess,
                         UInt32			inNumChannels,
                         bool &			ioSilence);
    
	// resets the filter state
	virtual void Reset();
};

#pragma mark -
class SimpleSpectrum : public AUEffectBase
{
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
	    
	// we'll report a 1ms tail.   A reverb effect would have a much more substantial tail on
	// the order of several seconds....
	//
	virtual	bool				SupportsTail() { return true; }
    virtual Float64				GetTailTime() { return 0.001; }
    
	// we have no latency
	//
    virtual Float64				GetLatency() {return 0.0; }
};

AUDIOCOMPONENT_ENTRY(AUBaseFactory, SimpleSpectrum)

static CFStringRef kBlockSize_Name = CFSTR("Block");
static CFStringRef kSelectChannel_Name = CFSTR("Channel");
static CFStringRef kWindow_Name = CFSTR("Window");

const float kBlockSize_Option1 = 1;
const float kBlockSize_Option2 = 2;
const float kBlockSize_Option3 = 3;
const float kBlockSize_Option4 = 4;
const float kBlockSize_Option5 = 5;

static CFStringRef kBlockSize_Option1_Name = CFSTR ("1024");
static CFStringRef kBlockSize_Option2_Name = CFSTR ("2048");
static CFStringRef kBlockSize_Option3_Name = CFSTR ("4096");
static CFStringRef kBlockSize_Option4_Name = CFSTR ("8192");
static CFStringRef kBlockSize_Option5_Name = CFSTR ("16384");

const float kBlockSize_Default = kBlockSize_Option1;

const float kSelectChannel_Left = 1;  
const float kSelectChannel_Right = 2; 
const float kSelectChannel_Both = 3;

static CFStringRef kSelectChannel_Left_Name = CFSTR ("Left");
static CFStringRef kSelectChannel_Right_Name = CFSTR ("Right");
static CFStringRef kSelectChannel_Both_Name = CFSTR ("Both");

const float kSelectChannel_Default = kSelectChannel_Both;

const float kWindow_Rectangular = 1;
const float kWindow_Hann = 2;
const float kWindow_KayserBessel = 3;

static CFStringRef kWindow_Rectangular_Name = CFSTR ("Rectangular");
static CFStringRef kWindow_Hann_Name = CFSTR ("Hann");
static CFStringRef kWindow_KeyserBessel_Name = CFSTR ("Keyser-Bessel");

const float kWindow_Default = kWindow_Hann;

#endif
