#version 440

in vec4 position;

out Data {
	vec3 l_dir;
	int instanceID;
} DataOut;

uniform vec4 l_dir;
uniform mat4 V;

void main()
{
    gl_Position = position;
    //DataOut.l_dir = normalize(vec3(V * -l_dir));
    DataOut.l_dir = normalize(vec3(-l_dir));
    DataOut.instanceID = gl_InstanceID;
}
