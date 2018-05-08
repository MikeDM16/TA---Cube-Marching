#version 440

uniform sampler3D grid;
uniform mat4 VM;
uniform float FOV;
uniform float RATIO;
uniform vec2 WindowSize;
uniform vec3 RayOrigin;
uniform int GridSize;
uniform int level = 0;

layout(points) in;
layout(triangle_strip, max_vertices = 24) out;

uniform mat4 PVM;

vec4 objCube[8]; // Object space coordinate of cube corner
vec4 ndcCube[8]; // Normalized device coordinate of cube corner
ivec4 faces[6];  // Vertex indices of the cube faces

/* Parameters to ray marching */
struct Ray {
    vec3 Origin;
    vec3 Dir;
};

struct AABB {
    vec3 Min;
    vec3 Max;
};

bool IntersectBox(Ray r, AABB aabb, out float t0, out float t1)
{
    vec3 invR = 1.0 / r.Dir;
    vec3 tbot = invR * (aabb.Min-r.Origin);
    vec3 ttop = invR * (aabb.Max-r.Origin);
    vec3 tmin = min(ttop, tbot);
    vec3 tmax = max(ttop, tbot);
    // vec2 t = max(tmin.xx, tmin.yz);
    // t0 = max(t.x, t.y);
    // t = min(tmax.xx, tmax.yz);
    // t1 = min(t.x, t.y);
 	 t0 = max(tmin.x, max(tmin.y, tmin.z));
	 t1 = min(tmax.x, min(tmax.y, tmax.z));
   return t0 <= t1;
}

void emit_vert(int vert)
{
    gl_Position = ndcCube[vert];
    EmitVertex();
}

void emit_face(int face)
{
    emit_vert(faces[face][1]); 
    emit_vert(faces[face][0]);
    emit_vert(faces[face][3]); 
    emit_vert(faces[face][2]);
    EndPrimitive();
    
}

void main()
{
    float densidade; 
    for(int i=0; i < GridSize; i++){
        for(int j=0; j < GridSize; j++){
            for(int k=0; k < GridSize; k++){
                vec3 pos = vec3(i,j,k);
                densidade = texelFetch(grid, ivec3((pos) * GridSize/pow(2.0,level)), level).r ;
            }
        }
    }
    
        faces[0] = ivec4(0,1,3,2); faces[1] = ivec4(5,4,6,7);
        faces[2] = ivec4(4,5,0,1); faces[3] = ivec4(3,2,7,6);
        faces[4] = ivec4(0,3,4,7); faces[5] = ivec4(2,1,6,5);

        vec4 P = vec4(0,0,0,1);
        vec4 I = vec4(1,0,0,0);
        vec4 J = vec4(0,1,0,0);
        vec4 K = vec4(0,0,1,0);

        objCube[0] = P+K+I+J; objCube[1] = P+K+I-J;
        objCube[2] = P+K-I-J; objCube[3] = P+K-I+J;
        objCube[4] = P-K+I+J; objCube[5] = P-K+I-J;
        objCube[6] = P-K-I-J; objCube[7] = P-K-I+J;

        // Transform the corners of the box:
        for (int vert = 0; vert < 8; vert++)
            ndcCube[vert] = PVM * objCube[vert];

        // Emit the six faces:
        for (int face = 0; face < 6; face++)
            emit_face(face);

}