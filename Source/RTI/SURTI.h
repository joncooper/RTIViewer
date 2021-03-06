//
//  SURTI.h
//  PTMViewer
//
//  Created by Jon Cooper on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "JLGLProgram.h"

struct SUSphericalCoordinate {
    double theta;
    double phi;
};
typedef struct SUSphericalCoordinate *SUSphericalCoordinate;

@interface SURTI : NSObject

@property (readonly, nonatomic, assign) NSUInteger fileType;
@property (readonly, nonatomic, assign) NSUInteger width;
@property (readonly, nonatomic, assign) NSUInteger height;
@property (readonly, nonatomic, assign) NSUInteger bands;
@property (readonly, nonatomic, assign) NSUInteger terms;
@property (readonly, nonatomic, assign) NSUInteger basisType;
@property (readonly, nonatomic, assign) NSUInteger elementSize;
@property (readonly, nonatomic, assign) NSUInteger order;

@property (readonly, nonatomic, assign) Float32 *scale;
@property (readonly, nonatomic, assign) Float32 *bias;
@property (readonly, nonatomic, strong) NSData *coefficients;

@property (readonly, nonatomic, assign) GLuint *textures;
@property (readonly, nonatomic, assign) Float32 *weights;

@property (readonly, nonatomic, strong) JLGLProgram *shaderProgram;

- (id)initWithURL:(NSURL *)url;

- (void)parseHeaders;
- (void)parse;
 
- (void)setupGL;
- (void)bindAttributes;
- (void)bindUniforms;
- (void)setupUniforms;
- (void)uploadTextures;
- (void)unbindTextures;

- (void)updateWeights:(SUSphericalCoordinate)lightLocation;
- (void)computeWeights:(SUSphericalCoordinate)lightLocation;

@end
