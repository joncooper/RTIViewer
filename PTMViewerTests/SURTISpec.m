//
//  SUBinaryFileReaderSpec.m
//  PTMViewer
//
//  Created by Jon Cooper on 6/27/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "SURTI.h"

#define WITHIN_EPSILON(x, y, e) (e > (abs(x - y))

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
    it(@"reads the correct number of coefficients", ^{
        
    });
    it(@"reads the coefficients in the correct order", ^{
        
    });
});

SPEC_END