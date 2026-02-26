uniform Image Background;

uniform float MotionThreshold;
uniform float AdaptionRate;

vec4 effect(vec4 colour, Image Input, vec2 inputPosition, vec2 screenPosition) {
	vec3 inputPixel = Texel(Input, inputPosition).rgb;
	vec3 backgroundPixel = Texel(Background, inputPosition).rgb;

	vec3 difference = abs(inputPixel - backgroundPixel);
	float motion = step(MotionThreshold, dot(difference, vec3(0.3, 0.587, 0.114)));

	return vec4(motion, 0.0, 0.0, 1.0);
}