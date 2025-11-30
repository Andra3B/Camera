uniform Image uvImage;

vec4 effect(vec4 colour, Image yImage, vec2 imagePosition, vec2 screenPosition) {	
	float halfImagePositionY = imagePosition.y * 0.5;
	
	float y = Texel(yImage, imagePosition).r;
    float u = Texel(uvImage, vec2(imagePosition.x, halfImagePositionY)).r - 0.5;
    float v = Texel(uvImage, vec2(imagePosition.x, 0.5 + halfImagePositionY)).r - 0.5;

	// BT.601 YUV to RGB conversion
    return vec4(
		y + 1.402 * v,
		y - 0.344136 * u - 0.714136 * v,
		y + 1.772 * u,
		1.0
	);
}