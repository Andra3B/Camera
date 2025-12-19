// Motion Tracking Pass 3: decay (make motion fade away for smoother tracking)

uniform Image PreviousMotion;

uniform float LowerThreshold;
uniform float HigherThreshold;

// How slowly the motion fades away. Higher values result in slower decay.
uniform float Decay;

vec4 effect(vec4 colour, Image currentMotion, vec2 imagePosition, vec2 screenPosition) {	
	float currentMotionValue = Texel(currentMotion, imagePosition).r;
	float previousMotionValue = Texel(PreviousMotion, imagePosition).r;

	float motion = max(currentMotionValue, previousMotionValue * Decay);

	return vec4(motion, motion, motion, 1.0);
}