//
//  SimpleSpectrum_GraphView.m
//  SimpleSprectrumAnalyzer
//
//  Created by Fred G on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleSpectrum_GraphView.h"

@implementation SimpleSpectrum_GraphView

#pragma mark ____ (INIT /) DEALLOC ____
-(void)awakeFromNib
{
    mSpectrum = malloc(DEFAULT_HSCALE * sizeof(Float32));
    mScale.h = DEFAULT_HSCALE;
    mScale.v = DEFAULT_VSCALE;
}

-(void)dealloc
{
    free(mSpectrum);
    [[self openGLContext] release];
}

#pragma mark ____ PUBLIC METHODS ____
-(void)resetScale:(Point)scale
{
    assert(scale.h > 0);
    mScale = scale;
    if(mSpectrum)
        free(mSpectrum);
    mSpectrum = malloc(scale.h * sizeof(Float32));
}

-(void)prepareOpenGL
{    
    glDisable(GL_DEPTH_TEST);
    
    glClearColor(0.01f, 0.01f, 0.01f, 0.0f);
    
    glMatrixMode (GL_PROJECTION);
    glLoadIdentity ();
    
    gluOrtho2D(0, mScale.h, 0, mScale.v);
    
    // for testing purpose
    [self fillSpectrumWithTestCoordinates];
}

-(void)reshape
{    
    NSSize newSize = self.superview.bounds.size;
    
    glMatrixMode(GL_PROJECTION);
    glViewport(0, 0, newSize.width, newSize.height);
    
    //[super setNeedsDisplay:YES];
    //[[self openGLContext] update]; 
}

-(void)drawRect:(NSRect)dirtyRect
{    
    glClear(GL_COLOR_BUFFER_BIT);
    
    glMatrixMode (GL_MODELVIEW);
    glLoadIdentity();
    //Displacement trick for exact pixelization
    glTranslatef(0.375, 0.375, 0);
    
    glBegin(GL_LINE_STRIP);
    glColor3ub(20, 250, 0);
    for(unsigned i = 0; i< mScale.h; ++i)
        glVertex2i(i, mSpectrum[i] * mScale.v);
    
    glEnd();
    
    // flush the buffer! (send drawing to the screen)
    [[self openGLContext] flushBuffer];
}

-(void)fillSpectrumWithTestCoordinates
{
    srand((UInt)time(NULL));
    for(UInt i = 0, maxnum = 0; i < 2*mScale.h; ++i) {
        if(i>=mScale.h) {
            UInt j = i % mScale.h;
            mSpectrum[j] /=  maxnum; // normalized over [0,1]
            continue;
        }
        
        mSpectrum[i] = rand();
        maxnum = max(mSpectrum[i], maxnum);
    }
}

@end
