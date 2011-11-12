//
//  Spectrum.h
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifndef SimpleSprectrumAnalyzer_Spectrum_h
#define SimpleSprectrumAnalyzer_Spectrum_h

#include "AUEffectBase.h"
#include "CASpectralProcessor.h"

#if AU_DEBUG_DISPATCHER
#include "AUDebugDispatcher.h"
#endif

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
    OSStatus Render(AudioUnitRenderActionFlags		&ioActionFlags,
                    const AudioTimeStamp &			inTimeStamp,
                    UInt32							inFramesToProcess );
	virtual OSStatus GetProperty(AudioUnitPropertyID 	inID,
                                 AudioUnitScope 		inScope,
                                 AudioUnitElement 		inElement,
                                 void 					* outData );
    virtual OSStatus GetPropertyInfo(AudioUnitPropertyID	inID,
                                     AudioUnitScope			inScope,
                                     AudioUnitElement		inElement,
                                     UInt32 &				outDataSize,
                                     Boolean &              outWritable );
	virtual OSStatus GetParameterInfo(AudioUnitScope            inScope,
                                      AudioUnitParameterID      inParameterID,
                                      AudioUnitParameterInfo	&outParameterInfo );
	    
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

#endif
