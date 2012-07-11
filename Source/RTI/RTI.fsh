/*

The fragment shader (GLSL) calculates each pixel's intensity by:
  * Sampling the coefficient from the texture array (which coerces it to a float)
  * Rehydrating it by applying the scale and bias
  * Multiplying it by the appropriate polynomial term weight
  * Summing those weighted, rehydrated coefficients
  
*/

varying highp vec2 pos;

uniform highp float scale[9];
uniform highp float bias[9];
uniform highp float weights[9];

uniform lowp sampler2D rtiData0;
uniform lowp sampler2D rtiData1;
uniform lowp sampler2D rtiData2;
uniform lowp sampler2D rtiData3;
uniform lowp sampler2D rtiData4;
uniform lowp sampler2D rtiData5;
uniform lowp sampler2D rtiData6;
uniform lowp sampler2D rtiData7;
uniform lowp sampler2D rtiData8;

void main() {
    gl_FragColor = clamp(texture2D(rtiData0, vec2(0.10, 0.15)), 0.0, 1.0);
    
    //gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
    //gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
    
    /*

  gl_FragColor  = (texture2D(rtiData0, pos) * scale[0] + bias[0]) * weights[0];
  gl_FragColor += (texture2D(rtiData1, pos) * scale[1] + bias[1]) * weights[1];
  gl_FragColor += (texture2D(rtiData2, pos) * scale[2] + bias[2]) * weights[2];
  gl_FragColor += (texture2D(rtiData3, pos) * scale[3] + bias[3]) * weights[3];
  gl_FragColor += (texture2D(rtiData4, pos) * scale[4] + bias[4]) * weights[4];
  gl_FragColor += (texture2D(rtiData5, pos) * scale[5] + bias[5]) * weights[5];
  gl_FragColor += (texture2D(rtiData6, pos) * scale[6] + bias[6]) * weights[6];
  gl_FragColor += (texture2D(rtiData7, pos) * scale[7] + bias[7]) * weights[7];
  gl_FragColor += (texture2D(rtiData8, pos) * scale[8] + bias[8]) * weights[8];
  gl_FragColor.a = 1.0;
*/
}