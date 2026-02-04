vec4 effect(vec4 colour, Image motionMask, vec2 imagePosition, vec2 screenPosition) {
	return vec4(
		imagePosition,
		Texel(motionMask, imagePosition).r,
		1.0
	);
}