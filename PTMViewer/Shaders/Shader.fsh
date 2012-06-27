//
//  Shader.fsh
//  PTMViewer
//
//  Created by Jon Cooper on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
