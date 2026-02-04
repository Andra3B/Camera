uniform Image PreviousMotionMask;

uniform float LowerThreshold;
uniform float HigherThreshold;

vec4 effect(vec4 colour, Image currentFrame, vec2 imagePosition, vec2 screenPosition) {
	vec3 currentPixel = Texel(currentFrame, imagePosition).rgb;
	
	float currentLuminance = (currentPixel.r + currentPixel.g + currentPixel.b) * 0.33;
	float previousLuminance = Texel(PreviousMotionMask, imagePosition).g;

	float currentMotion = abs(currentLuminance - previousLuminance);
	float previousMotion = Texel(PreviousMotionMask, imagePosition).r;

	float finalMotion;

	if (previousMotion > 0.0) {
		finalMotion = step(LowerThreshold, currentMotion);
	} else {
		finalMotion = step(HigherThreshold, currentMotion);
	}

	return vec4(finalMotion, currentLuminance, 0.0, 1.0);
}