// Motion Tracking Pass 2: 3x3 blur (reduce sparkle noise)

uniform vec2 Pixel;

vec4 effect(vec4 colour, Image sourceImage, vec2 imagePosition, vec2 screenPosition) {	
	float sum = 0.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			sum += Texel(sourceImage, imagePosition + vec2(x, y) * Pixel).r;
		}
	}

	float blurredResult = sum / 9.0;

	return vec4(blurredResult, blurredResult, blurredResult, 1.0);
}