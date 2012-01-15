//
//  Spectrum.cpp
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#include "SimpleSpectrum.h"

#define kMaxBlockSize 16384

#pragma mark ____SimpleSpectrumKernel
SimpleSpectrumKernel::SimpleSpectrumKernel(AUEffectBase * inAudioUnit ) : AUKernelBase(inAudioUnit)
{
    
}

void SimpleSpectrumKernel::Process(Float32 const* inSourceP,
                                     Float32 * inDestP,
                                     UInt32 inFramesToProcess,
                                     UInt32 inNumChannels,
                                     bool & ioSilence)
{
	//This code will pass-thru the audio data.
	//This is usually where you want to process data to produce an effect.
    
}

#pragma mark ____SimpleSpectrum
SimpleSpectrum::SimpleSpectrum(AudioUnit component) : AUEffectBase(component)
{
	// all the parameters must be set to their initial values here
	//
	// these calls have the effect both of defining the parameters for the first time
	// and assigning their initial values
	//
    SetParameter(kSpectrumParam_BlockSize, kBlockSize_Default);
    SetParameter(kSpectrumParam_SelectChannel, kSelectChannel_Default);
    SetParameter(kSpectrumParam_Window, kWindow_Default);
    
	SetParamHasSampleRateDependency(false);
}

OSStatus SimpleSpectrum::Initialize() 
{
	OSStatus result = AUEffectBase::Initialize();
	
	if(result == noErr ) {
        // allocate our ring buffer
        mProcessor.Allocate(GetNumberOfChannels(), kMaxBlockSize);
        mComputedMagnitudes.alloc(kMaxBlockSize >> 1);
        
        mInfos.mNumBins = 0;
        mInfos.mNumChannels = GetNumberOfChannels();
        mInfos.mSamplingRate = GetSampleRate();
	}
	
	return result;
}

OSStatus SimpleSpectrum::Render(AudioUnitRenderActionFlags & ioActionFlags,
                          AudioTimeStamp const&	inTimeStamp,
                        UInt32 inFramesToProcess ) 
{	
    UInt32 actionFlags = 0;
	OSStatus err = PullInput(0, actionFlags, inTimeStamp, inFramesToProcess);
	if (err) return err;
    
    GetOutput(0)->PrepareBuffer(inFramesToProcess); // prepare the output buffer list	
	
	AudioBufferList& inputBufList = GetInput(0)->GetBufferList();

    mProcessor.CopyInputToRingBuffer(inFramesToProcess, &inputBufList);
   
    UInt32 currentBlockSize = pow(2, GetParameter(kSpectrumParam_BlockSize)+9);
    SimpleSpectrumProcessor::Window currentWindow = (SimpleSpectrumProcessor::Window) GetParameter(kSpectrumParam_Window);
    
    if(mProcessor.TryFFT(currentBlockSize, currentWindow)) {
        mInfos.mNumBins = currentBlockSize>>1;
        UInt32 channelSelect = GetParameter(kSpectrumParam_SelectChannel);
        
        if(mProcessor.GetMagnitudes(mComputedMagnitudes(), currentWindow, channelSelect)) {
            // notify UI
            PropertyChanged(kAudioUnitProperty_SpectrumGraphData, kAudioUnitScope_Global, 0);
        } 
    }

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
                                                             CFSTR("SpectrumCocoaView"),
                                                             CFSTR("bundle"),
                                                             NULL);
                
                if (bundleURL == NULL) return fnfErr;
                
				CFStringRef className = CFSTR("SimpleSpectrum_ViewFactory"); // name of the main class that implements the AUCocoaUIBase protocol
				AudioUnitCocoaViewInfo cocoaInfo = { bundleURL, className };
				*((AudioUnitCocoaViewInfo *)outData) = cocoaInfo;
				
				return noErr;
			}
            // This property gives infos about the computed magnitudes
            case kAudioUnitProperty_SpectrumGraphInfo:
            {
                SpectrumGraphInfo* g = (SpectrumGraphInfo*) outData;

                g->mNumBins = mInfos.mNumBins;
                g->mSamplingRate = mInfos.mSamplingRate;
                g->mNumChannels = mInfos.mNumChannels;

                return noErr;
            }
            // This property sends magnitudes data as Float32
            case kAudioUnitProperty_SpectrumGraphData:
            {
                Float32* mData = (Float32*) outData;
                
                if(mInfos.mNumBins > 0) {
                    memcpy(mData, mComputedMagnitudes(), mInfos.mNumBins * sizeof(Float32));
                }
            }
		}
	}

	return AUEffectBase::GetProperty (inID, inScope, inElement, outData);
}

OSStatus SimpleSpectrum::GetPropertyInfo(AudioUnitPropertyID	inID,
                                  AudioUnitScope		inScope,
                                  AudioUnitElement		inElement,
                                  UInt32 &				outDataSize,
                                  Boolean &				outWritable) 
{
	if (inScope == kAudioUnitScope_Global) 	{
		switch (inID) {
			case kAudioUnitProperty_CocoaUI:
				outWritable = false;
				outDataSize = sizeof (AudioUnitCocoaViewInfo);
				return noErr;
            case kAudioUnitProperty_SpectrumGraphInfo:
				outWritable = false;
				outDataSize = sizeof (SpectrumGraphInfo);
				return noErr;
            case kAudioUnitProperty_SpectrumGraphData:
                outWritable = false;
                outDataSize = mInfos.mNumBins * sizeof(Float32);
                return noErr;
		}
	}
	
	return AUEffectBase::GetPropertyInfo (inID, inScope, inElement, outDataSize, outWritable);
}

OSStatus SimpleSpectrum::GetParameterValueStrings(AudioUnitScope inScope, 
                                                  AudioUnitParameterID inParameterID, 
                                                  CFArrayRef *outStrings) 
{
    if (inScope == kAudioUnitScope_Global) {
		switch(inParameterID)
		{
            case kSpectrumParam_BlockSize:
            {
                if (outStrings == NULL) return noErr;   
                
                CFStringRef options [] = {
                    kBlockSize_Option1_Name,
                    kBlockSize_Option2_Name,
                    kBlockSize_Option3_Name,
                    kBlockSize_Option4_Name,
                    kBlockSize_Option5_Name
                };
                
                *outStrings = CFArrayCreate (NULL,
                                             (const void **) options,
                                             (sizeof (options) / sizeof (options[0])),
                                             NULL
                                             );
                return noErr;                
                break;
            }
            case kSpectrumParam_SelectChannel:
            {
                if (outStrings == NULL) return noErr;   
                
                CFStringRef options [] = {
                    kSelectChannel_Left_Name,
                    kSelectChannel_Right_Name,
                    kSelectChannel_Both_Name
                };
                
                *outStrings = CFArrayCreate (NULL,
                                             (const void **) options,
                                             (sizeof (options) / sizeof (options[0])),
                                             NULL
                                             );
                return noErr;                
                break;
            }
            case kSpectrumParam_Window:
            {
                if (outStrings == NULL) return noErr;   
                
                CFStringRef options [] = {
                    kWindow_Rectangular_Name,
                    kWindow_Hann_Name,
                    kWindow_Hamming_Name,
                    kWindow_Blackman_Name
                };
                
                *outStrings = CFArrayCreate (NULL,
                                             (const void **) options,
                                             (sizeof (options) / sizeof (options[0])),
                                             NULL
                                             );
                return noErr;                
                break;
            }
        }
	}
    
	return kAudioUnitErr_InvalidParameter;
}

OSStatus SimpleSpectrum::GetParameterInfo(AudioUnitScope inScope,
                                    AudioUnitParameterID inParameterID,
                                    AudioUnitParameterInfo & outParameterInfo ) 
{
	OSStatus result = noErr;
    
	outParameterInfo.flags = 	
        kAudioUnitParameterFlag_IsWritable + 
        kAudioUnitParameterFlag_IsReadable;
    
	if (inScope == kAudioUnitScope_Global) {
		switch(inParameterID)
		{
			case kSpectrumParam_BlockSize:
				AUBase::FillInParameterName (outParameterInfo, kBlockSize_Name, false);
				outParameterInfo.unit = kAudioUnitParameterUnit_Indexed;
				outParameterInfo.minValue = kBlockSize_Option1;
				outParameterInfo.maxValue = kBlockSize_Option5;
				outParameterInfo.defaultValue = kBlockSize_Default;
				break;
				
            case kSpectrumParam_SelectChannel:
                AUBase::FillInParameterName (outParameterInfo, kSelectChannel_Name, false);
                outParameterInfo.unit = kAudioUnitParameterUnit_Indexed;
                outParameterInfo.minValue = kSelectChannel_Left;
                outParameterInfo.maxValue = kSelectChannel_Both;
                outParameterInfo.defaultValue = kSelectChannel_Default;
                break;
                
			case kSpectrumParam_Window:
				AUBase::FillInParameterName (outParameterInfo, kWindow_Name, false);
				outParameterInfo.unit = kAudioUnitParameterUnit_Indexed;
				outParameterInfo.minValue = kWindow_Rectangular;
				outParameterInfo.maxValue = kWindow_Blackman;
				outParameterInfo.defaultValue = kWindow_Default;
				break;
				
			default:
				result = kAudioUnitErr_InvalidParameter;
				break;
		}
	} else {
		result = kAudioUnitErr_InvalidParameter;
	}
	
	return result;
}
