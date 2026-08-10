shader_type canvas_item;

// La máscara: negro = oculto, blanco = dibujado (visible)
uniform sampler2D mask : filter_linear;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float drawn = texture(mask, UV).r;
	COLOR = vec4(base.rgb, base.a * drawn);
}