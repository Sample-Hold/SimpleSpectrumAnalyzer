//
//  Spectrum.cpp
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#include "SimpleSpectrum.h"

#pragma mark ____SimpleSpectrumKernel
SimpleSpectrumKernel::SimpleSpectrumKernel(AUEffectBase *inAudioUnit ) : AUKernelBase(inAudioUnit) {
	Reset();
}

SimpleSpectrumKernel::~SimpleSpectrumKernel() {
    
}

void SimpleSpectrumKernel::Reset() {
	// TODO : Reset stuffs here
}

void SimpleSpectrumKernel::Process(const Float32 	*inSourceP,
                             Float32 		*inDestP,
                             UInt32 	    inFramesToProcess,
                             UInt32			inNumChannels, // for version 2 AudioUnits inNumChannels is always 1
                             bool &			ioSilence) {
	// pass-thru since we don't process any audio data
}

#pragma mark ____SimpleSpectrum
SimpleSpectrum::SimpleSpectrum(AudioUnit component) : AUEffectBase(component) {
	// all the parameters must be set to their initial values here
	//
	// these calls have the effect both of defining the parameters for the first time
	// and assigning their initial values
	//

	SetParamHasSampleRateDependency(true);
}

OSStatus SimpleSpectrum::Initialize() {
	OSStatus result = AUEffectBase::Initialize();
	
	if(result == noErr ) {
		// in case the AU was un-initialized and parameters were changed
	}
	
	return result;
}

OSStatus SimpleSpectrum::Render(AudioUnitRenderActionFlags & ioActionFlags,
                          AudioTimeStamp const&	inTimeStamp,
                        UInt32 inFramesToProcess ) {
	return AUEffectBase::Render(ioActionFlags, inTimeStamp, inFramesToProcess);
    
}

OSStatus SimpleSpectrum::GetProperty(AudioUnitPropertyID  inID, 
                               AudioUnitScope		inScope,
                               AudioUnitElement		inElement,
                               void *				outData) {
	if (inScope == kAudioUnitScope_Global)
	{
		switch (inID) {
            // This property allows the host application to find the UI associated with this
            // AudioUnit
			case kAudioUnitProperty_CocoaUI:
			{
				// Look for a resource in the main bundle by name and type.
				CFBundleRef bundle = CFBundleGetBundleWithIdentifier(CFSTR("com.fred.SimpleSpectrumAnalyzer"));
				
				if (bundle == NULL) return fnfErr;
                
				CFURLRef bundleURL = CFBundleCopyResourceURL( bundle, 
                                                             CFSTR("SpectrumCocoaView"), // this is the name of the cocoa bundle
                                                             CFSTR("bundle"), // this is the extension of the cocoa bundle
                                                             NULL);
                
                if (bundleURL == NULL) return fnfErr;
                
				CFStringRef className = CFSTR("SimpleSpectrum_ViewFactory");	// name of the main class that implements the AUCocoaUIBase protocol
				AudioUnitCocoaViewInfo cocoaInfo = { bundleURL, className };
				*((AudioUnitCocoaViewInfo *)outData) = cocoaInfo;
				
				return noErr;
			}
		}
	}
	
	// if we've gotten this far, handles the standard properties
	return AUEffectBase::GetProperty (inID, inScope, inElement, outData);
}

OSStatus SimpleSpectrum::GetPropertyInfo(AudioUnitPropertyID	inID,
                                  AudioUnitScope		inScope,
                                  AudioUnitElement		inElement,
                                  UInt32 &				outDataSize,
                                  Boolean &				outWritable) {
	if (inScope == kAudioUnitScope_Global) 	{
		switch (inID) {
			case kAudioUnitProperty_CocoaUI:
				outWritable = false;
				outDataSize = sizeof (AudioUnitCocoaViewInfo);
				return noErr;
		}
	}
	
	return AUEffectBase::GetPropertyInfo (inID, inScope, inElement, outDataSize, outWritable);
}

OSStatus SimpleSpectrum::GetParameterInfo(AudioUnitScope          inScope,
                                    AudioUnitParameterID	inParameterID,
                                    AudioUnitParameterInfo	&outParameterInfo ) {
	OSStatus result = noErr;
    
	//outParameterInfo.flags = kAudioUnitParameterFlag_IsReadable;
	
	return result;
}