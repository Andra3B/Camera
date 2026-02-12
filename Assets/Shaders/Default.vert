vec4 position(mat4 projectionMatrix, vec4 vertexPosition) {
	return projectionMatrix*vertexPosition;
}