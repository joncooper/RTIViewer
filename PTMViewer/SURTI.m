//
//  SURTI.m
//  PTMViewer
//
//  Created by Jon Cooper on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SURTI.h"
#import "SUBinaryFileReader.h"
#include <stdlib.h>

struct SUSphericalCoordinate {
    double theta;
    double phi;
};
typedef struct SUSphericalCoordinate SUSphericalCoordinate;
    
// Returns the index of an element in the coefficient array
// h - y position of the current pixel
// w - x position of the current pixel
// b - the current color channel
// o - the current term (keep in mind there are order*order terms)

#define GET_INDEX(h, w, b, o) (h * (_width * _bands * _order * _order) + w * (_bands * _order * _order) + b * (_order * _order) + o) 

@implementation SURTI {
    SUBinaryFileReader *_binaryFileReader;
}

@synthesize fileType = _fileType;
@synthesize width = _width;
@synthesize height = _height;
@synthesize bands = _bands;
@synthesize terms = _terms;
@synthesize basisType = _basisType;
@synthesize elementSize = _elementSize;
@synthesize order = _order;

@synthesize scale = _scale;
@synthesize bias = _bias;
@synthesize coefficients = _coefficients;

@synthesize weights = _weights;

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _binaryFileReader = [[SUBinaryFileReader alloc] initWithURL:url]; 
    }
    return self;
}

- (void)parseHeaders {
    // Strip all header comment lines
    while ([[_binaryFileReader peekLine] characterAtIndex:0] == '#')
        [_binaryFileReader readLine];
    
    _fileType = [[_binaryFileReader readLine] integerValue];
    NSArray *header_line_2 = [[_binaryFileReader readLine] componentsSeparatedByString:@" "];
    NSArray *header_line_3 = [[_binaryFileReader readLine] componentsSeparatedByString:@" "];
    
    _width = [[header_line_2 objectAtIndex:0] integerValue];
    _height = [[header_line_2 objectAtIndex:1] integerValue];
    _bands = [[header_line_2 objectAtIndex:2] integerValue];
    _terms = [[header_line_3 objectAtIndex:0] integerValue];
    _basisType = [[header_line_3 objectAtIndex:1] integerValue];
    _elementSize = [[header_line_3 objectAtIndex:2] integerValue];
    _order = sqrt(_terms);
    
    NSLog(@"Dimensions: %d x %d", _width, _height);
    NSLog(@"Bands: %d", _bands);
    NSLog(@"Terms: %d", _terms);
    NSLog(@"Basis Type: %d", _basisType);
    NSLog(@"Element Size: %d", _elementSize);
    
    NSAssert(_fileType == 3, @"Cannot parse non-HSH file type.");
    
    _scale = (Float32 *)calloc(_terms, sizeof(Float32));
    [_binaryFileReader readFloat32:&_scale count:_terms];
    
    _bias = (Float32 *)calloc(_terms, sizeof(Float32));
    [_binaryFileReader readFloat32:&_bias count:_terms];
}

- (void)parse {        
    [self parseHeaders];
    
    NSUInteger coefficentCount = _width * _height * _bands * _terms;
    _coefficients = malloc(coefficentCount * sizeof(UInt8));
    
    for (int y = 0; y < _height; y++) {
        for (int x = 0; x < _width; x++) {
            for (int b = 0; b < _bands; b++) {
                for (int t = 0; t < _terms; t++) {
                    _coefficients[GET_INDEX(y, x, b, t)] = [_binaryFileReader readUInt8];
                }
            }
        }
    }
}

- (void)computeWeights:(SUSphericalCoordinate)lightLocation {
    _weights = malloc(16 * sizeof(Float32));
    
    double theta = lightLocation.theta;
    double phi = lightLocation.phi;
    
    if (phi < 0)
        phi = phi + (2 * M_PI);
    
    _weights[0]  = 1/sqrt(2*M_PI);
    _weights[1]  = sqrt(6/M_PI)      * (cos(phi)*sqrt(cos(theta)-cos(theta)*cos(theta)));
    _weights[2]  = sqrt(3/(2*M_PI))  * (-1 + 2*cos(theta));
    _weights[3]  = sqrt(6/M_PI)      * (sqrt(cos(theta) - cos(theta)*cos(theta))*sin(phi));
    _weights[4]  = sqrt(30/M_PI)     * (cos(2*phi)*(-cos(theta) + cos(theta)*cos(theta)));
    _weights[5]  = sqrt(30/M_PI)     * (cos(phi)*(-1 + 2*cos(theta))*sqrt(cos(theta) - cos(theta)*cos(theta)));
    _weights[6]  = sqrt(5/(2*M_PI))  * (1 - 6*cos(theta) + 6*cos(theta)*cos(theta));
    _weights[7]  = sqrt(30/M_PI)     * ((-1 + 2*cos(theta))*sqrt(cos(theta) - cos(theta)*cos(theta))*sin(phi));
    _weights[8]  = sqrt(30/M_PI)     * ((-cos(theta) + cos(theta)*cos(theta))*sin(2*phi));
    _weights[9]  = 2*sqrt(35/M_PI)   * cos(3*phi)*pow(cos(theta) - cos(theta)*cos(theta),(3/2));
    _weights[10] = (sqrt(210/M_PI)   * cos(2*phi)*(-1 + 2*cos(theta))*(-cos(theta) + cos(theta)*cos(theta)));
    _weights[11] = 2*sqrt(21/M_PI)   * cos(phi)*sqrt(cos(theta) - cos(theta)*cos(theta))*(1 - 5*cos(theta) + 5*cos(theta)*cos(theta));
    _weights[12] = sqrt(7/(2*M_PI))  * (-1 + 12*cos(theta) - 30*cos(theta)*cos(theta) + 20*cos(theta)*cos(theta)*cos(theta));
    _weights[13] = 2*sqrt(21/M_PI)   * sqrt(cos(theta) - cos(theta)*cos(theta))*(1 - 5*cos(theta) + 5*cos(theta)*cos(theta))*sin(phi);
    _weights[14] = (sqrt(210/M_PI)   * (-1 + 2*cos(theta))*(-cos(theta) + cos(theta)*cos(theta))*sin(2*phi));
    _weights[15] = 2*sqrt(35/M_PI)   * pow(cos(theta) - cos(theta)*cos(theta),(3/2))*sin(3*phi);
}
 
- (void)dealloc {
    free(_scale);
    free(_bias);
    free(_coefficients);
    free(_weights);
}

@end
