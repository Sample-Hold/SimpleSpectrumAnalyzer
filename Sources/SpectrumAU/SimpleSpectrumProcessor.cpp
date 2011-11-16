//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 14/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#include "SimpleSpectrumProcessor.h"

#include "CABitOperations.h"

#define MIN(a,b) a<b?a:b
#define MAX(a,b) a>b?a:b
#define OFFSETOF(class, field)((size_t)&((class*)0)->field)

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

void SimpleSpectrumProcessor::debugData(char const* message, Float32 * f, size_t s) 
{
    printf(message, "");
    for(int i = 0; i < s; ++i)
        printf("%i: %f\n", i, *(f+i));
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
    printf("SimpleSpectrumProcessor::CopyInputToRingBuffer()->%u\n", (unsigned)inNumFrames);
    
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
            memcpy(mChannels[i].mRingBufferData, (UInt8*)inInput->mBuffers[i].mData + firstPartBytes, secondPartBytes);
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
    printf("SimpleSpectrumProcessor::InitFFT()->%u\n", (unsigned)FFTSize);

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
        mChannels[i].mDSPSplitComplex.realp = mChannels[i].mSplitData();
        mChannels[i].mDSPSplitComplex.imagp = mChannels[i].mSplitData() + bins;
	}
    
    mWindowData.alloc(FFTSize);
}

void SimpleSpectrumProcessor::ExtractRingBufferToFFTInput(UInt32 inNumFrames)
{
    printf("SimpleSpectrumProcessor::ExtractRingBufferToFFTInput()->%u\n", (unsigned)inNumFrames);
    
    UInt32 numBytes = inNumFrames * sizeof(Float32);
    UInt32 firstPart = mRingBufferCapacity - mRingBufferPosRead;
    // Overlap-Add to FFT Buffer
    if (firstPart < inNumFrames) {
        UInt32 firstPartBytes = firstPart * sizeof(Float32);
        UInt32 secondPartBytes = numBytes - firstPartBytes;
        for(UInt32 i = 0; i < mNumChannels; ++i){
            memcpy(mChannels[i].mInputData, mChannels[i].mRingBufferData() + mRingBufferPosRead, firstPartBytes);
            memcpy(mChannels[i].mInputData() + firstPart, mChannels[i].mRingBufferData, secondPartBytes);
        }
    }
    else {
		for (UInt32 i=0; i<mNumChannels; ++i) {
			memcpy(mChannels[i].mInputData, mChannels[i].mRingBufferData() + mRingBufferPosRead, numBytes);
        }
    }
    
    mRingBufferPosRead = (mRingBufferPosRead + inNumFrames) & (mRingBufferCapacity-1);
    mRingBufferCount -= inNumFrames;
}

void SimpleSpectrumProcessor::ApplyWindow(Window w)
{
    printf("SimpleSpectrumProcessor::ApplyWindow()->%u\n", (unsigned)w);
    
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
        vDSP_vmul(mChannels[i].mInputData(), 1, mWindowData(), 1, mChannels[i].mOutputData(), 1, mFFTSize);
}

bool SimpleSpectrumProcessor::TryFFT(UInt32 inNumFrames, Window w) 
{
    printf("SimpleSpectrumProcessor::TryFFT()->%u\n", (unsigned)inNumFrames);
    
    inNumFrames = NextPowerOfTwo(inNumFrames);
    
    if(inNumFrames > mRingBufferCount - mRingBufferPosRead) // not enough data
        return false;
    
    UInt32 log2FFTSize = Log2Ceil(inNumFrames);
    UInt32 bins = inNumFrames>>1;
    
    if(!mFFTSetupCreated || mFFTSize != inNumFrames)
        InitFFT(inNumFrames, log2FFTSize, bins);
    
    ExtractRingBufferToFFTInput(inNumFrames);
    
    ApplyWindow(w);
    
    for (UInt32 i=0; i<mNumChannels; ++i) 
	{
		vDSP_ctoz((DSPComplex*)mChannels[i].mOutputData(), 2, &mChannels[i].mDSPSplitComplex, 1, bins);
		vDSP_fft_zrip(mFFTSetup, &mChannels[i].mDSPSplitComplex, 1, log2FFTSize, FFT_FORWARD);
    }

    return true;
}

bool SimpleSpectrumProcessor::GetMagnitudes(Float32 *outMagnitude, Float32 * min, Float32 * max, int channelSelect)
{
    printf("SimpleSpectrumProcessor::GetMagnitudes()->%d\n", channelSelect);
    
    UInt32 bins = mFFTSize>>1;
    Float32 numberOfChannels(mNumChannels);
    CAAutoArrayDelete<Float32> minMagnitudesByChannel,  maxMagnitudesByChannel; 
    CAAutoFree<Float32> temp;
    minMagnitudesByChannel.alloc(mNumChannels);
    maxMagnitudesByChannel.alloc(mNumChannels);
    temp.alloc(bins);
    
    for (UInt32 i=0; i<mNumChannels; ++i) {
        vDSP_zvabs(&mChannels[i].mDSPSplitComplex, 1, mChannels[i].mOutputData(), 1, bins);
        vDSP_minmgv(mChannels[i].mOutputData(), 1, &minMagnitudesByChannel[i], bins);
        vDSP_maxmgv(mChannels[i].mOutputData(), 1, &maxMagnitudesByChannel[i], bins);
    }
    
    if (channelSelect == -1 && mNumChannels > 1 && mNumChannels < 3) { // we only support up to 2 channels
        vDSP_vsadd(mChannels[0].mOutputData(), 1, mChannels[1].mOutputData(), temp(), 1, bins);
        vDSP_vsdiv(temp(), 1, &numberOfChannels, outMagnitude, 1, bins);
        
        *min = (minMagnitudesByChannel[0] + minMagnitudesByChannel[1]) / 2;
        *max = (maxMagnitudesByChannel[0] + maxMagnitudesByChannel[1]) / 2;
        
        return true;
    }
    
    if (channelSelect >= 0 && channelSelect < mNumChannels) {
        memcpy(outMagnitude, mChannels[channelSelect].mOutputData(), bins * sizeof(Float32));
        
        *min = minMagnitudesByChannel[channelSelect];
        *max = maxMagnitudesByChannel[channelSelect];
        
        return true;
    }
    
    return false;
}