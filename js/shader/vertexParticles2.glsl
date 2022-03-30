precision highp float;

attribute vec2 uv;
attribute vec3 position;
uniform sampler2D posTex;
uniform sampler2D color;
uniform sampler2D scaleTex;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;
uniform float time;
uniform float duration;
uniform float envStart;
uniform bool interpolate;
uniform bool glow;
uniform float nebulaAmp;

uniform float fade;
uniform float fdAlpha;
uniform float scale;
uniform float size;
uniform bool nebula;

varying float opacity;
varying vec3 vColor;
varying float vScale;
varying float depth;
varying float fogDepth;

uniform float focalDistance;
uniform float aperture;
uniform float maxParticleSize;

uniform vec3 tint;
uniform vec3 hoverPoint;
uniform float hover;

varying float vRing;
varying float vLevels;

//
// Description : Array and textureless GLSL 2D/3D/4D simplex 
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20201014 (stegu)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
// 

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
     return mod289(((x*34.0)+10.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v)
  { 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);


  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;


  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y


  i = mod289(i); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

  float n_ = 0.142857142857; // 1.0/7.0
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
  //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

  //Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

  // Mix final noise value
  vec4 m = max(0.5 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 105.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
  }


  // uniform vec2 viewport;

const vec2 TILE = vec2(1.0/8.0, -1.0/8.0);

vec3 getPosition(vec2 tc) {
	vec3 pos = texture2D(posTex, tc).rgb;
	vec3 p = vec3(-1.0) + 2.0 * pos;
	return p * scale;
}

vec2 getUVTile(float tile) {
	float x = mod(tile, 8.0) / 8.0;
	float y = 1.0-floor(tile/8.0) / 8.0;
	return vec2(x,y) + uv * TILE;
}

/* float exponentialOut(float t) {
	return t == 1. ? 1. : 1. - pow(2., -10. * t);
	// return t == 1.0 ? t : 1.0 - pow(2.0, -10.0 * t);
}

float cubicOut(float t) {
	float f = t - 1.0;
	return f * f * f + 1.0;
}

float quarticOut(float t) {
	return pow(t - 1.0, 3.0) * (1.0 - t) + 1.0;
} */

float qinticOut(float t) {
	return 1.0 - (pow(1.0-t, 5.0));
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453123);
}

vec3 grayscale(vec3 col) {
	return vec3(length(col));
}

const vec3 color1 = vec3(0.00, 0.14, 0.64);
const vec3 color2 = vec3(0.39, 0.52, 0.97);
const vec3 color3 = vec3(0.51, 0.17, 0.75);

const float hoverOpacity = .35;

uniform vec4 interaction;
uniform float iRadius;

void main () {
	vec3 p = position;
	float ptScale = 1.0;

	if(nebula) {
		// float progress = smoothstep(0., duration, time);
		float pr = smoothstep(0., duration, time);
		float progress = qinticOut(pr);
		float tile = progress*63.0;
		float tile0 = floor(tile);
		float tile1 = ceil(tile);
		vec2 uv0 = getUVTile(tile0);
		vec2 uv1 = getUVTile(tile1);

		bool sampleOnce = time >= duration;

		if(sampleOnce) {
		// if(true) {
			vec3 p1 = getPosition(uv0);
			vec3 p2 = getPosition(uv0);
      // p1 = p;// ----
			p = p1*1000.;
  
			vColor = texture2D(color, uv0).rgb;
      // vColor = vec3(p2*10.);
		} else {
			vec3 p1 = getPosition(uv0);
			vec3 p2 = getPosition(uv1);

      p1 = p1*1000.;// ----
      p2 = p2*1000.;// ----
			float t = fract(tile);
			p = interpolate ? mix(p1, p2, t) : p1;

			vec4 color1 = texture2D(color, uv0);
			vec4 color2 = texture2D(color, uv1);
			vec4 _color = interpolate ? mix(color1, color2, t) : color1;
			vColor = _color.rgb;
		}
		ptScale = texture2D(scaleTex, uv).r;
		ptScale *= smoothstep(0. , .1, length(p));

		vec3 p2;
		float amp = mix(nebulaAmp, nebulaAmp*.4, fade);
		float t = time * .08;
		p2.x = amp * snoise(vec3(position.xy*.01, t));
		p2.z = amp * snoise(vec3(position.zy*.01, t *1.1));
		p2.y = p2.x;

		p.z = mix(p.z, p.z + 45.0 * snoise(vec3(p.xy * .0075, time *.01)), fdAlpha);

		float pt = smoothstep(.5, 1., progress);
		p = mix(p, p+p2, pt);

    // p = position;
    // ptScale = 190.;
    // vColor = vec3(uv1,0.);
	} else {
		float progress = smoothstep(envStart, duration, time);
		float r = .5 * rand(position.xz * .01);
		progress = smoothstep(r, 1., progress);

		p.x += 100.0 * sin(time*.01 + p.x);
		p.y += 100.0 * cos(time*.02 + p.y);
		p.z += 100.0 * sin(time*.026 + p.z);

		progress = qinticOut(progress);
		ptScale *= smoothstep(0.0, 0.2, progress);

		p *= progress;

		float radius = sqrt(p.x*p.x+p.y*p.y);

		vColor = mix(color1, color2, smoothstep(0., 100.0, radius));
		vColor = mix(vColor, color3, smoothstep(100., 200.0, radius));
	}

	vLevels = step(10., length(p));

	if(fade > 0.0) {
		float d = smoothstep(0.0, 200.0, distance(vec3(0.), p));
		opacity = mix(1.0, d, fade);
	}
	else {
		opacity = 1.0;
	}

	if(nebula) {
		opacity *= ptScale;
	} else {
		opacity *= smoothstep(envStart, duration, time);
	}

	vScale = ptScale;

	float t = time * .05;
	vec3 cN = .25 * vec3(
		snoise(vec3(position.xy * .1, t)),
		snoise(vec3(position.xz * .1, t)),
		snoise(vec3(position.yz * .1, t))
	);

	// hover tint
	vec3 hColor = vColor * hoverOpacity;
	vec4 worldPosition = modelMatrix * vec4(p, 1.0);
	float hPD = distance(hoverPoint, worldPosition.xyz);
	float hD = smoothstep(30.0, 80.0, hPD);
	hColor = mix(tint, hColor, hD);

	float opacity2 = mix(opacity, opacity * hoverOpacity, hD);
	opacity = mix(opacity, opacity2, hover);

	vColor = mix(vColor, tint + cN, fade);
	vColor = mix(vColor, hColor, hover);

	float iD = distance(worldPosition.xyz, interaction.xyz);
	float iR = mix(iRadius, iRadius/2.0, fade);
	float sId = 1.0 - smoothstep(iR, iR*2.5, iD);
	vec3 iV = normalize(interaction.xyz-worldPosition.xyz);

	float ringAngle = atan(position.y, position.x) + time;
	float ringY = 4.0 * snoise(vec3(position.xy, time*.1));
	vec3 ringPosition = interaction.xyz  + vec3(iR*sin(ringAngle), ringY, iR*cos(ringAngle));
	float ringX = 4.0 * snoise(vec3(position.xy, time*.1));
	vec3 ringPosition2 = interaction.xyz  + vec3(iR*sin(ringAngle), iR*cos(ringAngle), ringX);

	vec3 trPos = worldPosition.x<interaction.x ? ringPosition2 : ringPosition;

	worldPosition.xyz = mix(worldPosition.xyz, trPos, sId * interaction.w);

	vRing = sId * interaction.w;
	
	vec4 mvPos = viewMatrix * worldPosition;

	float distanceToCamera = -mvPos.z;
	float fD = mix(focalDistance, 50.0, fdAlpha);
	float CoC = distance(distanceToCamera, fD);
	
	float ap = mix(aperture, 200.0, fdAlpha);

	depth = 1.0 - smoothstep(0.0, ap, CoC);
	// depth = mix(depth, 1.0, 1.0-hD);
	ptScale = mix(ptScale, 4.0*ptScale, 1.0 - depth);
	ptScale = mix(ptScale, ptScale*2.0, sId*interaction.w);

	if(glow) {
		ptScale = mix(ptScale, ptScale*.5, fdAlpha);
	}

	float near = mix(1000.0, 0., fdAlpha);
	float far = mix(1500.0, 525.0, fdAlpha);

	fogDepth = 1.0 - smoothstep(near, far, -mvPos.z);

	float maxS = mix(maxParticleSize, maxParticleSize*2.5, fade);
	gl_PointSize =  ptScale*min(maxS, 1000.0 * size / (-mvPos.z));
	gl_Position = projectionMatrix * mvPos;


  // vec4 mvPosition = modelViewMatrix * vec4( position, 1. );
  // gl_PointSize = 3. * ( 1. / - mvPosition.z );
  // gl_Position = projectionMatrix * mvPosition;
}