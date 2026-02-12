uniform vec2 TexelSize;

vec4 effect(vec4 colour, Image Input, vec2 inputPosition, vec2 screenPosition) {
	vec2 base = inputPosition*2.0;

	float motionSum =
		Texel(Input, base + vec2(-0.5, -0.5)*TexelSize).r +
		Texel(Input, base + vec2(0.5, -0.5)*TexelSize).r +
		Texel(Input, base + vec2(-0.5, 0.5)*TexelSize).r +
		Texel(Input, base + vec2(0.5, 0.5)*TexelSize).r;
	
	return vec4(step(0.25, motionSum*0.25), 0.0, 0.0, 1.0);
}