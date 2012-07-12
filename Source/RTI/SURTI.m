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
    
#define GET_TEXTURE_INDEX(y, x, b) ((y * (_width * _bands)) + (x * _bands) + b)

#define GET_INDEX(h, w, b, o) (h * (_width * _bands * _order * _order) + w * (_bands * _order * _order) + b * (_order * _order) + o) 

struct RTIUniforms {
    GLint scale;
    GLint bias;
    GLint weights;
    GLint modelViewProjectionMatrix;
    GLint rtiData[9];
};
typedef struct RTIUniforms *RTIUniforms;

@implementation SURTI {
    SUBinaryFileReader *_binaryFileReader;
    BOOL               _hasTexturesBound;
    RTIUniforms        _uniforms;
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
        _uniforms = calloc(1, sizeof(struct RTIUniforms));
    }
    return self;
}

#pragma mark - Parsing

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

- (void)parse {        
    [self parseHeaders];
    
    int coefficentCount = _width * _height * _bands * _terms;
    NSData *coefficients;
    
    [_binaryFileReader readNSData:&coefficients count:coefficentCount];
    _coefficients = coefficients;
}

#pragma mark - GL

//
// Bind the shaders
//
- (void)setupGL {
    
    [self bindAttributes];
    [self.shaderProgram link];
    [self.shaderProgram use];
    
    [self bindUniforms];
    [self uploadTextures];
    [self setupUniforms];
}

- (void)bindAttributes {
    [self.shaderProgram addAttribute:@"position"];
    [self.shaderProgram addAttribute:@"uv"];
}

- (void)bindUniforms {
    _uniforms->scale                     = [self.shaderProgram uniformIndex:@"scale"];
    _uniforms->bias                      = [self.shaderProgram uniformIndex:@"bias"];
    _uniforms->weights                   = [self.shaderProgram uniformIndex:@"weights"];
    _uniforms->modelViewProjectionMatrix = [self.shaderProgram uniformIndex:@"modelViewProjectionMatrix"];
    
    for (int i = 0; i < 9; i++) {
        _uniforms->rtiData[i] = [self.shaderProgram uniformIndex:[NSString stringWithFormat:@"rtiData%i", i]];
    }
}

- (void)setupUniforms {
    glUniform1fv(_uniforms->scale, 9, _scale);
    glUniform1fv(_uniforms->bias, 9, _bias);
    
    // TODO: the typedef doesn't need to be a pointer
    SUSphericalCoordinate overhead = calloc(1, sizeof(struct SUSphericalCoordinate));
    overhead->theta = 0.35f;
    overhead->phi = M_PI;
    [self updateWeights:overhead];
    
    /*
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(-1.0f, 1.0f, 1.0f, -1.0f, -1.0f, 100.0f);
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.5f);
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, baseModelViewMatrix);
    glUniformMatrix4fv(_uniforms->modelViewProjectionMatrix, 1, 0, modelViewProjectionMatrix.m);
    */
    
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0.0f, 640.0f, 0.0f, 960.0f, -1.0f, 1.0f);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Scale(GLKMatrix4Identity, 640.0f, 640.0f, 1.0f);
    GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    glUniformMatrix4fv(_uniforms->modelViewProjectionMatrix, 1, 0, mvpMatrix.m);
    
    for (int i = 0; i < 9; i++) {
        glUniform1i(_uniforms->rtiData[i], i);
    }
}

//
// Copy coordinates to GPU using glTexImage2D, then nuke them from userspace RAM.
//
- (void)uploadTextures {
    NSAssert(_terms == 9, @"At the moment we only support 3rd order RTI files.");
    NSAssert(_hasTexturesBound == NO, @"Textures already bound, unbind first.");
    
    _textures = calloc(_terms, sizeof(GLuint));
                       
    glGenTextures(_terms, _textures);
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
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
        glActiveTexture(GL_TEXTURE0 + t);
        glBindTexture(GL_TEXTURE_2D, _textures[t]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
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

- (void)updateWeights:(SUSphericalCoordinate)lightLocation {
    [self computeWeights:lightLocation];
    glUniform1fv(_uniforms->weights, 9, _weights);
}

- (void)computeWeights:(SUSphericalCoordinate)lightLocation {
    _weights = calloc(16, sizeof(Float32));
    
    double theta = lightLocation->theta;
    double phi = lightLocation->phi;
    
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
    free(_uniforms);
}

@end
