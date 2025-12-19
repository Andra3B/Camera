// Motion Tracking Pass 1: luminance filter (initial noise reduction) + Frame differencing

uniform Image PreviousDifferenceLuminance;

// FilterFactor controls how fast the filter responds to change. Larger values result in a faster response.
uniform float FilterFactor;

uniform float FilterGain;

vec4 effect(vec4 colour, Image currentFrame, vec2 imagePosition, vec2 screenPosition) {	
	float currentLuminance = dot(Texel(currentFrame, imagePosition).rgb, vec3(0.299, 0.587, 0.114));
	float currentFilteredLuminance = mix(Texel(PreviousDifferenceLuminance, imagePosition).g, currentLuminance, FilterFactor);
	float difference = abs(currentLuminance - currentFilteredLuminance) * FilterGain;

	return vec4(difference, currentFilteredLuminance, 0.0, 1.0);
}