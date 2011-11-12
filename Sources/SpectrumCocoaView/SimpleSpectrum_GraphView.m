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
    testSize = 50;
    testCoordinates = malloc(testSize * sizeof(float));
    fillWithTestCoordinates(testCoordinates, testSize);
}

-(void)dealloc
{
    free(testCoordinates);
    
    [super dealloc];
}

#pragma mark ____ PUBLIC METHODS ____
-(void)prepareOpenGL
{    
    glDisable(GL_DEPTH_TEST);
    glClearColor(0.01f, 0.01f, 0.01f, 0.0f);
    
    glMatrixMode (GL_PROJECTION);
    glLoadIdentity ();
    glOrtho(0, testSize, testSize, 0, 0, 1);
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
    glColor3ub(255, 255, 0);
    
    for(unsigned i = 0; i< testSize; ++i) {
        glVertex2i(i, testCoordinates[i] * testSize);
    }
    
    glEnd();
    
    // flush the buffer! (send drawing to the screen)
    [[self openGLContext] flushBuffer];
}

#pragma mark ____ INTERNAL METHODS ____
void fillWithTestCoordinates(float * output, unsigned outputSize) {
    srand((unsigned)time(NULL));
    for(unsigned i = 0, maxnum = 0; i<2*outputSize; ++i) {
        if(i>=outputSize) {
            unsigned j = i%outputSize;
            output[j] =  output[j] / maxnum; // normalized over [0,1]
            continue;
        }
        
        output[i] = rand();
        maxnum = max(output[i], maxnum);
    }
}

@end
