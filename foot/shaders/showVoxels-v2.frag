#version 440

in Data {
    vec3 normal;
    vec3 l_dir;
} DataIn;

out vec4 FragColor;


void main() {
	/*
    vec3 n = normalize(DataIn.normal);
    
    float intensity = max(0.0, dot(n, DataIn.l_dir));
    FragColor = intensity * vec4(0.7, 0.7, 0.7, 1);*/
    FragColor = vec4(0.7, 0.7, 0.7, 1);
}