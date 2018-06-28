#version 440

in vec4 position;

out Data {
	int instanceID;
	vec3 l_dir;
} DataOut;

uniform vec4 l_dir;
uniform mat4 V;

void main()
{
    gl_Position = position;
    DataOut.instanceID = gl_InstanceID;
    DataOut.l_dir = vec3(normalize(- (V * l_dir)));
}
