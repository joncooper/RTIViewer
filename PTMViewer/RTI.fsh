/*

The fragment shader (GLSL) calculates each pixel's intensity by:
  * Sampling the coefficient from the texture array (which coerces it to a float)
  * Rehydrating it by applying the scale and bias
  * Multiplying it by the appropriate polynomial term weight
  * Summing those weighted, rehydrated coefficients
  
*/

varying vec2 pos;

uniform float scale[9];
uniform float bias[9];
uniform float weights[9];

uniform sampler2D rtiData[9];

void main() {

  gl_FragColor  = (texture2D(rtiData[0], pos) * scale[0] + bias[0]) * weights[0];
  gl_FragColor += (texture2D(rtiData[1], pos) * scale[1] + bias[1]) * weights[1];
  gl_FragColor += (texture2D(rtiData[2], pos) * scale[2] + bias[2]) * weights[2];
  gl_FragColor += (texture2D(rtiData[3], pos) * scale[3] + bias[3]) * weights[3];
  gl_FragColor += (texture2D(rtiData[4], pos) * scale[4] + bias[4]) * weights[4];
  gl_FragColor += (texture2D(rtiData[5], pos) * scale[5] + bias[5]) * weights[5];
  gl_FragColor += (texture2D(rtiData[6], pos) * scale[6] + bias[6]) * weights[6];
  gl_FragColor += (texture2D(rtiData[7], pos) * scale[7] + bias[7]) * weights[7];
  gl_FragColor += (texture2D(rtiData[8], pos) * scale[8] + bias[8]) * weights[8];
  gl_FragColor.a = 1.0;

}