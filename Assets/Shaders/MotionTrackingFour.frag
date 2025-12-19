// Motion Tracking Pass 4: Encode center of motion parameters

vec4 effect(vec4 colour, Image motionMask, vec2 imagePosition, vec2 screenPosition) {	
	float motion = Texel(motionMask, imagePosition).r;
	
	return vec4(imagePosition * motion, motion, 1.0);
}