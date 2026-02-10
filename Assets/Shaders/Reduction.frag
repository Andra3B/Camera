uniform vec2 TexelSize;

vec4 effect(vec4 colour, Image inputFrame, vec2 imagePosition, vec2 screenPosition) {
	vec2 base = imagePosition*2.0;

	vec4 topLeft = Texel(inputFrame, base + vec2(-0.5, -0.5)*TexelSize);
	vec4 topRight = Texel(inputFrame, base + vec2(0.5, -0.5)*TexelSize);
	vec4 bottomLeft = Texel(inputFrame, base + vec2(-0.5, 0.5)*TexelSize);
	vec4 bottomRight = Texel(inputFrame, base + vec2(0.5, 0.5)*TexelSize);

	float motionSum = topLeft.b + topRight.b + bottomLeft.b + bottomRight.b;

	if (motionSum > 0.0001) {
		return vec4(
			((topLeft.x*topLeft.b) + (topRight.x*topRight.b) + (bottomLeft.x*bottomLeft.b) + (bottomRight.x*bottomRight.b)) / motionSum,
			((topLeft.y*topLeft.b) + (topRight.y*topRight.b) + (bottomLeft.y*bottomLeft.b) + (bottomRight.y*bottomRight.b)) / motionSum,
			motionSum,
			1.0
		);
	} else {
		return vec4(0.0, 0.0, 0.0, 1.0);
	}
}