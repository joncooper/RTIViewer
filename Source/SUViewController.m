//
//  SUViewController.m
//  PTMViewer
//
//  Created by Jon Cooper on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SUViewController.h"
#import "SURTI.h"

//GLfloat quadVertices[8] = {
//    -1.0f, -1.0f, // Bottom left
//    1.0f, -1.0f, // Bottom right
//    -1.0f,  1.0f, // Top left
//    1.0f,  1.0f  // Top right 
//};
//

/*
GLfloat quadTexCoord[8] = {
    0.0f, 0.0f, // Bottom left
    1.0f, 0.0f, // Bottom right
    0.0f, 1.0f, // Top left
    1.0f, 1.0f  // Top right 
};
*/

GLfloat quadTexCoord[8] = {
    0.0f, 1.0f, // Top left
    1.0f, 1.0f, // Top right 
    0.0f, 0.0f, // Bottom left
    1.0f, 0.0f  // Bottom right
};


GLfloat quadVertices[8] = {
    -1.0f, -1.0f, // Bottom left
    1.0f,  -1.0f, // Bottom right
    -1.0f, 1.0f, // Top left
    1.0f, 1.0f  // Top right 
};

@interface SUViewController () {
    SURTI *_rti;
    GLuint _positionAttribute;
    GLuint _texCoordAttribute;
    
    SUSphericalCoordinate _lightPosition;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation SUViewController

@synthesize context = _context;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    [self setupGL];
    [self setupRTI];
}

- (void)setupRTI
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *url = [bundle URLForResource:@"coin" withExtension:@"rti"];
    
    _rti = [[SURTI alloc] initWithURL:url];
    [_rti parse];
    [_rti setupGL];
    [[_rti shaderProgram] use];
    
    _positionAttribute = [_rti.shaderProgram attributeIndex:@"position"];
    _texCoordAttribute = [_rti.shaderProgram attributeIndex:@"uv"];

    glEnableVertexAttribArray(_positionAttribute);
    glEnableVertexAttribArray(_texCoordAttribute);
    
    glVertexAttribPointer(_positionAttribute, 2, GL_FLOAT, GL_FALSE, 0, quadVertices);
    glVertexAttribPointer(_texCoordAttribute, 2, GL_FLOAT, GL_FALSE, 0, quadTexCoord);    
    
    _lightPosition = calloc(1, sizeof(struct SUSphericalCoordinate));
    _lightPosition->theta = M_PI / 4.0f; // Rotation on zy plane
    _lightPosition->phi = 0.0f;   // Rotation on xy plane
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    _lightPosition->phi += (2.0f * M_PI) / (60.0f * 2.0f);
    [_rti updateWeights:_lightPosition];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Red == Bad
    glClearColor(0.8f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);  
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.paused = !self.paused;
}

/*
  
 Shader setup:
 
 - create program
 - compile shaders
 - attach shaders to program
 - bind attribute locations
 - link
 - get uniform locations
 
 */

#pragma mark - UIViewController stuff

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
