// Motion Tracking Pass 5: Reduction to get center of motion

uniform vec2 SourcePixel;

vec4 effect(vec4 colour, Image sourceImage, vec2 imagePosition, vec2 screenPosition) {	
	imagePosition = imagePosition * 2;

	return (
		Texel(sourceImage, imagePosition) +
		Texel(sourceImage, imagePosition + vec2(SourcePixel.x, 0.0)) + 
		Texel(sourceImage, imagePosition + vec2(0.0, SourcePixel.y)) +
		Texel(sourceImage, imagePosition + SourcePixel)
	) * 0.3;
}