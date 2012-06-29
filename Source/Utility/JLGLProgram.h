//
//  Attributed to Jeff LaMarche (http://github.com/jlamarche)
// 
//  JLGLProgram.h
//  RTIViewer
//
//  Created by Jon Cooper on 6/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


@interface JLGLProgram : NSObject

- (id)initWithVertexShaderFilename:(NSString *)vShaderFilename 
            fragmentShaderFilename:(NSString *)fShaderFilename;
- (void)addAttribute:(NSString *)attributeName;
- (GLuint)attributeIndex:(NSString *)attributeName;
- (GLuint)uniformIndex:(NSString *)uniformName;
- (BOOL)link;
- (void)use;
- (NSString *)vertexShaderLog;
- (NSString *)fragmentShaderLog;
- (NSString *)programLog;

@end