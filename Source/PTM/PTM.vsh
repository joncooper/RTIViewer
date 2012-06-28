/*
Built-in variables:
- vec4  gl_Position
- float gl_PointSize
- vec4  gl_ClipVertex

Varying variables:
- vec4  gl_FrontColor
- vec4  gl_BackColor
- vec4  gl_FrontSecondaryColor
- vec4  gl_BackSecondaryColor
- vec4  gl_TexCoord[]
- float gl_FogFragCoord

Built-in attributes:
- vec4  gl_Color
- vec4  gl_SecondaryColor
- vec3  gl_Normal
- vec4  gl_Vertex
- vec4  gl_MultiTexCoord0..7
- float gl_FogCoord

Built-in uniform states:
- mat4  gl_ModelViewMatrix
- mat4  gl_ProjectionMatrix
- mat4  gl_ModelViewProjectionMatrix
- mat4  gl_TextureMatrix[gl_MaxTextureCoords]
- mat3  gl_NormalMatrix
- mat4  gl_ModelViewMatrixInverse
- mat4  gl_ProjectionMatrixInverse
- mat4  gl_ModelViewProjectionMatrixInverse; 
- mat4  gl_TextureMatrixInverse[gl_MaxTextureCoords]
- mat4  gl_ModelViewMatrixTranspose
- mat4  gl_ProjectionMatrixTranspose
- mat4  gl_ModelViewProjectionMatrixTranspose; 
- mat4  gl_TextureMatrixTranspose[gl_MaxTextureCoords]
- mat4  gl_ModelViewMatrixInverseTranspose
- mat4  gl_ProjectionMatrixInverseTranspose
- mat4  gl_ModelViewProjectionMatrixInverseTranspose
- mat4  gl_TextureMatrixInverseTranspose[gl_MaxTextureCoords]
- float gl_NormalScale
- ...

Built-in constants:
- int   gl_MaxLights 
- int   gl_MaxClipPlanes
- int   gl_MaxTextureUnits
- int   gl_MaxTextureCoords
- int   gl_MaxVertexAttribs
- int   gl_MaxVertexUniformComponents
- int   gl_MaxVaryingFloats
- int   gl_MaxVertexTextureImageUnits
- int   gl_MaxCombinedTextureImageUnits
- int   gl_MaxTextureImageUnits
- int   gl_MaxFragmentUniformComponents
- int   gl_MaxDrawBuffers
*/

void main()
{
	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
}