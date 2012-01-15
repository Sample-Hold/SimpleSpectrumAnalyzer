//
//  SimpleSpectrumProcessor.h
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 07/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

// We write a simpler version of PublicUtility/CASpectralProcessor here

#ifndef SimpleSprectrumAnalyzer_SimpleSpectrumProcessor_h
#define SimpleSprectrumAnalyzer_SimpleSpectrumProcessor_h

#include <Accelerate/Accelerate.h>

class SimpleSpectrumProcessor
{
public:
    enum Window { Rectangular = 1, Hann = 2, Hamming = 3, Blackman = 4 };
private:
    UInt32 mNumChannels;
    UInt32 mRingBufferCapacity;
    UInt32 mRingBufferPosRead;
    UInt32 mRingBufferPosWrite;
    UInt32 mRingBufferCount;
    
    UInt32 mFFTSize;
    FFTSetup mFFTSetup;
    bool mFFTSetupCreated;
    
    struct ChannelBuffers {
        CAAutoFree<Float32> mRingBufferData;
        CAAutoFree<Float32> mInputData;
        CAAutoFree<Float32> mSplitData;
        CAAutoFree<Float32> mOutputData;
        CAAutoFree<DSPSplitComplex> mDSPSplitComplex;
    };
    CAAutoArrayDelete<ChannelBuffers> mChannels;
    CAAutoFree<Float32> mWindowData;
protected:
    void InitFFT(UInt32 FFTSize, UInt32 log2FFTSize, UInt32 bins);
    void ExtractRingBufferToFFTInput(UInt32 inNumFrames);
    void ApplyWindow(Window w);
public:
    SimpleSpectrumProcessor();
    virtual ~SimpleSpectrumProcessor();
    
    void Allocate(UInt32 inNumChannels, UInt32 ringBufferCapacity);
    bool CopyInputToRingBuffer(UInt32 inNumFrames, AudioBufferList* inInput);
    bool TryFFT(UInt32 inFFTSize, Window w = Rectangular);
    bool GetMagnitudes(Float32 *result, const Window w, const UInt32 channelSelect = 3);
};

#endif