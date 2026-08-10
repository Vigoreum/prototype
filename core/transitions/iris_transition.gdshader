shader_type canvas_item;

// Progreso de 0.0 a 1.0
// 0.0 = pantalla totalmente cubierta (círculo grande de negro)
// 1.0 = pantalla totalmente visible (círculo desapareció)
uniform float progress: hint_range(0.0, 1.0) = 0.0;

// Centro del círculo en UV (0.5, 0.5 = centro de pantalla)
uniform vec2 center = vec2(0.5, 0.5);

// Color del círculo (negro por defecto)
uniform vec4 color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Aspect ratio para que el círculo no sea óvalo
uniform vec2 aspect = vec2(16.0, 9.0);

void fragment() {
	// Calcular distancia desde el centro, corrigiendo aspect ratio
	vec2 uv = UV - center;
	uv.x *= aspect.x / aspect.y;
	float dist = length(uv);
	
	// El radio del "círculo visible" depende del progress
	// Cuando progress = 0, radio = 0 (todo cubierto)
	// Cuando progress = 1, radio = grande (nada cubierto)
	float max_radius = 1.5;  // suficiente para cubrir toda la pantalla
	float radius = progress * max_radius;
	
	// Si la distancia es menor al radio, mostrar transparente (pasar)
	// Si es mayor, mostrar el color del círculo
	float alpha = step(radius, dist);
	
	COLOR = vec4(color.rgb, color.a * alpha);
}