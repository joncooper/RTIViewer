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
    
#define GET_TEXTURE_INDEX(y, x, b) (y * (_width * _height * _bands) + x * (_bands) + b)

#define GET_INDEX(h, w, b, o) (h * (_width * _bands * _order * _order) + w * (_bands * _order * _order) + b * (_order * _order) + o) 

@implementation SURTI {
    SUBinaryFileReader *_binaryFileReader;
    BOOL               _hasTexturesBound;
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

@synthesize textures = _textures;
@synthesize weights = _weights;

@synthesize shaderProgram = _shaderProgram;

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _binaryFileReader = [[SUBinaryFileReader alloc] initWithURL:url]; 
        _hasTexturesBound = NO;
        _shaderProgram = [[JLGLProgram alloc] initWithVertexShaderFilename:@"RTI" fragmentShaderFilename:@"RTI"];
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
    NSAssert(_terms <= 9, @"Shader implementation limited to 3rd-order HSH at this time."); 
    NSAssert(_bands == 3, @"RGB only at the moment.");
    
    _scale = calloc(_terms, sizeof(Float32));
    [_binaryFileReader readFloat32:&_scale count:_terms];
    
    _bias = calloc(_terms, sizeof(Float32));
    [_binaryFileReader readFloat32:&_bias count:_terms];
}

//
// Copy coordinates to GPU using glTexImage2D, then nuke them from userspace RAM.
//
- (void)bindTextures {
    NSAssert(_hasTexturesBound == NO, @"Textures already bound, unbind first.");
    
    _textures = calloc(_terms, sizeof(GLuint));
                       
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glGenTextures(_terms, _textures);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    const UInt8 *coefficientBytes = (const UInt8 *)[_coefficients bytes];
    int textureSize = _width * _height * _bands;
    UInt8 *textureData;
    
    for (int t = 0; t < _terms; t++) {
        textureData = calloc(textureSize, sizeof(UInt8));
        for (int y = 0; y < _height; y++) {
            for (int x = 0; x < _width; x++) {
                for (int b = 0; b < _bands; b++) {
                    textureData[GET_TEXTURE_INDEX(y, x, b)] = coefficientBytes[GET_INDEX(y, x, b, t)];
                }
            }
        }
        glBindTexture(GL_TEXTURE_2D, _textures[t]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _width, _height, 0, GL_RGB, GL_UNSIGNED_BYTE, textureData);
        
        free(textureData);
    }
}

- (void)unbindTextures {
    if (_hasTexturesBound)
        glDeleteTextures(_terms, _textures);
    
    free(_textures);
    
    _hasTexturesBound = NO;
}

//
// Bind the shaders
//
- (void)bindShaders {
    [self.shaderProgram link];
    [self.shaderProgram use];
}

//
// Update uniforms
//
- (void)updateUniforms {
    
}

- (void)parse {        
    [self parseHeaders];
    
    int coefficentCount = _width * _height * _bands * _terms;
    NSData *coefficients;
    
    [_binaryFileReader readNSData:&coefficients count:coefficentCount];
    _coefficients = coefficients;
}

- (void)computeWeights:(SUSphericalCoordinate)lightLocation {
    _weights = calloc(16, sizeof(Float32));
    
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
    [self unbindTextures];
    
    free(_scale);
    free(_bias);
    free(_weights);
}

@end
