//
//  SUBinaryFileReaderSpec.m
//  PTMViewer
//
//  Created by Jon Cooper on 6/0x27/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "SURTI.h"

SPEC_BEGIN(SURTISpec)

__block SURTI *rti;

beforeEach(^{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *url = [bundle URLForResource:@"coin" withExtension:@"rti"];
    rti = [[SURTI alloc] initWithURL:url];
});

describe(@"header parsing", ^{
    beforeEach(^{
        [rti parseHeaders];
    });
    it(@"parses the first header line", ^{
        [[theValue([rti fileType] == 3) should] beTrue];
    });
    it(@"parses the second header line", ^{
        [[theValue([rti width] == 600) should] beTrue];
        [[theValue([rti height] == 400) should] beTrue];
        [[theValue([rti bands] == 3) should] beTrue];
    });
    it(@"parses the third header line", ^{
        [[theValue([rti terms] == 9) should] beTrue];
        [[theValue([rti basisType] == 2) should] beTrue];
        [[theValue([rti elementSize] == 1) should] beTrue];
        [[theValue([rti order] == 3) should] beTrue];
    });
    it(@"parses the scale and bias values", ^{
        int terms = [rti terms];
        Float32 expectedScale[9] = { 
            1.14432,    1.27302,   1.02693,
            1.2622,     0.630076,  0.572815,
            0.77212,    0.745698,  0.607085  
        };
        Float32 expectedBias[9] = {  
            0.0535529, -0.685642, -0.222914,
            -0.662981,  -0.354366, -0.276839,
            -0.31945,   -0.423761, -0.296944  
        };
        for (int i = 0; i < terms; i++) {
            [[theValue([rti scale][i]) should] beWithin:theValue(0.00001) of:theValue(expectedScale[i])];
            [[theValue([rti bias][i]) should] beWithin:theValue(0.00001) of:theValue(expectedBias[i])];
        }
    });
});

describe(@"coefficient reading", ^{
    beforeEach(^{
        [rti parse];
    });
    it(@"reads the coefficients in the correct order", ^{
        
        // This is an RGB PTM, so the block is in format:
        // (9 terms of R), (9 terms of G), (9 terms of B)
        
        UInt8 firstCoefficientBlock[27] = {
            0x5C, 0x86, 0x94, 0x82, 0x94, 0x7B, 0x6C, 0x93, 0x79,
            0x5F, 0x85, 0x8F, 0x83, 0x94, 0x7C, 0x6C, 0x93, 0x79,
            0x67, 0x85, 0x8F, 0x83, 0x95, 0x7E, 0x6A, 0x90, 0x76
        };
        UInt8 lastCoefficientBlock[27] = {
            0x4A, 0x8E, 0x88, 0x7A, 0x96, 0x81, 0x6A, 0x98, 0x7D, 
            0x4B, 0x8E, 0x85, 0x7A, 0x95, 0x80, 0x6A, 0x99, 0x7C, 
            0x55, 0x91, 0x85, 0x79, 0x96, 0x7D, 0x69, 0x99, 0x7B
        };
        int totalCoefficientBlocks = [rti width] * [rti height] * [rti bands] * [rti terms];
        
        UInt8 *coefficients = [rti coefficients];
        for (int i = 0; i < 27; i++) {
            [[theValue(coefficients[i] == firstCoefficientBlock[i]) should] beTrue];
            [[theValue(coefficients[totalCoefficientBlocks - 27 + i] == lastCoefficientBlock[i]) should] beTrue];
        }
    });
});

SPEC_END