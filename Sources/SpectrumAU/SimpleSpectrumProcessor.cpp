//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 07/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#include "SimpleSpectrumProcessor.h"

#include "CABitOperations.h"

#define MIN(a,b) a<b?a:b
#define MAX(a,b) a>b?a:b

#pragma mark ____SimpleSpectrumProcessor
SimpleSpectrumProcessor::SimpleSpectrumProcessor(): mNumChannels(0), 
    mRingBufferPosRead(0), mRingBufferPosWrite(0), mRingBufferCount(0), mFFTSize(0),
    mFFTSetupCreated(false)
{
}

SimpleSpectrumProcessor::~SimpleSpectrumProcessor()
{
    if(mFFTSetupCreated)
        vDSP_destroy_fftsetup(mFFTSetup);
}

void SimpleSpectrumProcessor::Allocate(UInt32 inNumChannels, 
                                       UInt32 ringBufferCapacity)
{
    mNumChannels = inNumChannels;
    mRingBufferCapacity = NextPowerOfTwo(ringBufferCapacity);
    mRingBufferCount = (mRingBufferPosRead = ( mRingBufferPosWrite = 0));
    
    mChannels.alloc(mNumChannels);
    for(UInt32 i = 0; i < mNumChannels; ++i)
        mChannels[i].mRingBufferData.alloc(ringBufferCapacity);
}

bool SimpleSpectrumProcessor::CopyInputToRingBuffer(UInt32 inNumFrames, AudioBufferList* inInput)
{
    if(inNumFrames > mRingBufferCapacity)
        return false;
    
    UInt32 numBytes = inNumFrames * sizeof(Float32);
    UInt32 firstPart = mRingBufferCapacity - mRingBufferPosWrite;
    
    // Overlap-Add to RingBuffer
    if (firstPart < inNumFrames) {
        UInt32 firstPartBytes = firstPart * sizeof(Float32);
        UInt32 secondPartBytes = numBytes - firstPartBytes;
        for(UInt32 i = 0; i < mNumChannels; ++i){
            memcpy(mChannels[i].mRingBufferData() + mRingBufferPosWrite, inInput->mBuffers[i].mData, firstPartBytes);
            memcpy(mChannels[i].mRingBufferData(), (Float32*)inInput->mBuffers[i].mData + firstPart, secondPartBytes);
        }
    }
    else {
		for (UInt32 i=0; i<mNumChannels; ++i) {
			memcpy(mChannels[i].mRingBufferData() + mRingBufferPosWrite, inInput->mBuffers[i].mData, numBytes);
        }
    }
    
    mRingBufferPosWrite = (mRingBufferPosWrite + inNumFrames) & (mRingBufferCapacity-1);
    mRingBufferCount = MIN(mRingBufferCount + inNumFrames, mRingBufferCapacity);
    
    return true;
}

void SimpleSpectrumProcessor::InitFFT(UInt32 FFTSize, UInt32 log2FFTSize, UInt32 bins) 
{
    if(mFFTSetupCreated)
        vDSP_destroy_fftsetup(mFFTSetup);
    
    mFFTSetup = vDSP_create_fftsetup(log2FFTSize, FFT_RADIX2);
    mFFTSetupCreated = true;
    mFFTSize = FFTSize;

	for (UInt32 i = 0; i < mNumChannels; ++i) 
	{
		mChannels[i].mInputData.alloc(FFTSize, true);
		mChannels[i].mOutputData.alloc(FFTSize, true);
		mChannels[i].mSplitData.alloc(FFTSize, true);
        mChannels[i].mDSPSplitComplex.alloc(1);
        mChannels[i].mDSPSplitComplex->realp = mChannels[i].mSplitData();
        mChannels[i].mDSPSplitComplex->imagp = mChannels[i].mSplitData() + bins;
	}
    
    mWindowData.alloc(FFTSize);
}

void SimpleSpectrumProcessor::ExtractRingBufferToFFTInput(UInt32 inNumFrames)
{
    UInt32 numBytes = inNumFrames * sizeof(Float32);
    UInt32 firstPart = mRingBufferCapacity - mRingBufferPosRead;
    
    // Overlap-Add to FFT Buffer
    if (firstPart < inNumFrames) {
        UInt32 firstPartBytes = firstPart * sizeof(Float32);
        UInt32 secondPartBytes = numBytes - firstPartBytes;
        for(UInt32 i = 0; i < mNumChannels; ++i){
            memcpy(mChannels[i].mInputData(), mChannels[i].mRingBufferData() + mRingBufferPosRead, firstPartBytes);
            memcpy(mChannels[i].mInputData() + firstPart, mChannels[i].mRingBufferData(), secondPartBytes);
        }
    }
    else {
		for (UInt32 i=0; i<mNumChannels; ++i) {
			memcpy(mChannels[i].mInputData(), mChannels[i].mRingBufferData() + mRingBufferPosRead, numBytes);
        }
    }
    
    mRingBufferPosRead = (mRingBufferPosRead + inNumFrames) & (mRingBufferCapacity-1);
    mRingBufferCount -= inNumFrames;
}

void SimpleSpectrumProcessor::ApplyWindow(Window w)
{
    if (w == Rectangular)
        return;
    
    switch (w) {
        case Hann:
            vDSP_hann_window(mWindowData(), mFFTSize, vDSP_HANN_NORM);
            break;
        case Hamming:
            vDSP_hamm_window(mWindowData(), mFFTSize, 0);
            break;
        case Blackman:
            vDSP_blkman_window(mWindowData(), mFFTSize, 0);
            break;
        case Rectangular: // to avoid Xcode annoying warning
            break;
    }
    
    for (UInt32 i=0; i<mNumChannels; ++i)
        vDSP_vmul(mChannels[i].mInputData(), 1, mWindowData(), 1, mChannels[i].mInputData(), 1, mFFTSize);
}

bool SimpleSpectrumProcessor::TryFFT(UInt32 inNumFrames, Window w) 
{
    inNumFrames = NextPowerOfTwo(inNumFrames);
    
    if(inNumFrames > mRingBufferCount) // not enough data
        return false;
    
    UInt32 log2FFTSize = Log2Ceil(inNumFrames);
    UInt32 bins = inNumFrames>>1;
    
    if(!mFFTSetupCreated || mFFTSize != inNumFrames)
        InitFFT(inNumFrames, log2FFTSize, bins);
    
    ExtractRingBufferToFFTInput(inNumFrames);
    
    ApplyWindow(w);
    
    for (UInt32 i=0; i<mNumChannels; ++i) 
	{                
		vDSP_ctoz((DSPComplex*)mChannels[i].mInputData(), 2, mChannels[i].mDSPSplitComplex(), 1, bins);        
		vDSP_fft_zrip(mFFTSetup, mChannels[i].mDSPSplitComplex(), 1, log2FFTSize, FFT_FORWARD);
        
        // zero DC 
        *(mChannels[i].mDSPSplitComplex->realp) = 0;
        *(mChannels[i].mDSPSplitComplex->imagp) = 0;
    }

    return true;
}

CAAutoFree<Float32> SimpleSpectrumProcessor::GetMagnitudes(UInt32 channelSelect)
{
    UInt32 bins = mFFTSize>>1;
    Float32 two(2), fFFTSize(mFFTSize), ref(144);
    CAAutoArrayDelete<Float32> minMagnitudesByChannel,  maxMagnitudesByChannel; 
    CAAutoFree<Float32> result;
    minMagnitudesByChannel.alloc(mNumChannels);
    maxMagnitudesByChannel.alloc(mNumChannels);
    result.alloc(bins);
    
    for (UInt32 i=0; i<mNumChannels; ++i) {        
        // compute Z magnitude by saving sqrt operation
        vDSP_zvmags(mChannels[i].mDSPSplitComplex(), 1, mChannels[i].mOutputData(), 1, bins);

        // adjust magnitude
        vDSP_vsmul(mChannels[i].mOutputData(), 1, &two, mChannels[i].mOutputData(), 1, bins);
        vDSP_vsdiv(mChannels[i].mOutputData(), 1, &fFFTSize, mChannels[i].mOutputData(), 1, bins);
        
        // convert to Db
        vDSP_vdbcon(mChannels[i].mOutputData(), 1, &ref, mChannels[i].mOutputData(), 1, bins, 1);
        
        // find min max
        vDSP_minv(mChannels[i].mOutputData(), 1, &minMagnitudesByChannel[i], bins);
        vDSP_maxv(mChannels[i].mOutputData(), 1, &maxMagnitudesByChannel[i], bins);
    }
    
    // stereo analysis ; for this demo, we only support up to 2 channels
    if (channelSelect == 3 && mNumChannels > 1 && mNumChannels < 3) { 
        vDSP_vadd(mChannels[0].mOutputData(), 1, mChannels[1].mOutputData(), 1, result(), 1, bins);
        vDSP_vsdiv(result(), 1, &two, result(), 1, bins);
        
        return result;
    }
    
    // mono analysis
    if (channelSelect <= mNumChannels) {
        memcpy(result(), mChannels[channelSelect-1].mOutputData(), bins * sizeof(Float32));

        return result;
    }
    
    return result;
}