varying vec2 pos;

void main()
{
    gl_Position = gl_ModelViewProjectionMatrix * vec4(position, 1.0);
    pos = uv;
}