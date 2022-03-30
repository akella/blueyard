precision highp float;

uniform float globalAlpha;

varying float opacity;
uniform float superOpacity;
varying vec3 vColor;
varying float vScale;
uniform bool nebula;
varying float depth;
varying float fogDepth;
uniform bool glow;
uniform float fdAlpha;

varying float vRing;
varying float vLevels;

const float inGamma = 1.0; // 1.0
const float inWhite = 190.0; // 255.0;
const float inBlack = 10.0;

const float outBlack = 0.0;
const float outWhite = 250.0;

vec3 applyLevels(vec3 inPixel) {
	float r = (pow(((inPixel.r * 255.0) - inBlack) / (inWhite - inBlack), 1.0/inGamma) * (outWhite - outBlack) + outBlack) / 255.0; 
	float g = (pow(((inPixel.g * 255.0) - inBlack) / (inWhite - inBlack), 1.0/inGamma) * (outWhite - outBlack) + outBlack) / 255.0; 
	float b = (pow(((inPixel.b * 255.0) - inBlack) / (inWhite - inBlack), 1.0/inGamma) * (outWhite - outBlack) + outBlack) / 255.0; 

	return vec3(r,g,b);
} 

void main () {
	// if(globalAlpha < .001 || opacity < .001 || vScale < .001 || fogDepth < .001) discard;
	vec2 st = vec2(-1.0) + 2.0 * gl_PointCoord.xy;
	float d = 1.0 - distance(st, vec2(0.));

	// d = mix(d, smoothstep(0., .25, d), depth);
	if(!glow) d = smoothstep(0., .25, d);
	else d = mix(d, smoothstep(0., .25, d), depth);
	float depthOpacity = mix(.25, 1.0, depth);
	
	if(d < .001) discard;

	float op = d * opacity * globalAlpha * depthOpacity;
	// op = mix(op, smoothstep(.0, .4, op), fdAlpha);

	vec3 finalColor = mix(vColor, mix(vColor, vec3(1.), .35), vRing);
	finalColor = mix(finalColor, vec3(0.), 1.0-fogDepth);

	finalColor = mix(finalColor, applyLevels(finalColor), vLevels);

	gl_FragColor = vec4(finalColor, op * fogDepth*superOpacity);

	// gl_FragColor = vec4(1.,0.,1.,1.);
}