attribute vec4 position;
attribute vec4 uv;

// uniform vec4 modelViewProjectionMatrix;

varying vec2 pos;

void main()
{
    gl_Position = position;
    pos = uv.xy;
}