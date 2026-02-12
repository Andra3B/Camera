uniform Image FrameOne;
uniform Image FrameTwo;
uniform Image FrameThree;
uniform Image FrameFour;
uniform Image FrameFive;

vec4 effect(vec4 colour, Image image, vec2 framePosition, vec2 screenPosition) {
	return (
		Texel(FrameOne, framePosition) +
		Texel(FrameTwo, framePosition) +
		Texel(FrameThree, framePosition) +
		Texel(FrameFour, framePosition) +
		Texel(FrameFive, framePosition)
	)*0.2;
}