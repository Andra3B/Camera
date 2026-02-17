uniform Image PreviousBackground;
uniform float AdaptionRate;

vec4 effect(vec4 colour, Image frame, vec2 framePosition, vec2 screenPosition) {
	return mix(Texel(PreviousBackground, framePosition), Texel(frame, framePosition), AdaptionRate);
}