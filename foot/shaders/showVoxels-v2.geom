#version 440

/*
https://pastebin.com/DQ4Xjn7t
*/

layout(points) in;
layout(triangle_strip, max_vertices = 15) out;

layout(std430, binding = 1) buffer edgesBuffer {
    int EDGES[256];
};

layout(std430, binding = 2) buffer trianglesBuffer {
    int TRIANGLES[256][16];
};

uniform mat4 PVM;
uniform sampler3D grid;
uniform int GridSize;
uniform int level = 0;

float ISO_LEVEL = 0.0f;
float NORMAL_SMOOTHNESS = 1.0f;
int lod = 4;

float densities[8];
ivec3 corners[8];
vec3 vertices[12];

vec3 interpolation(vec3 p1, vec3 p2, float valp1, float valp2) {
    float mu;
    vec3 p; 

    mu = (ISO_LEVEL - valp1) / (valp2 - valp1);
    p.x = p1.x + mu * float(p2.x - p1.x);
    p.y = p1.y + mu * float(p2.y - p1.y);
    p.z = p1.z + mu * float(p2.z - p1.z);

    return p;
}

void main()
{
    int mul = int(pow(2, lod));
    
    for (int x = 0; x < GridSize; x += mul) {
        for (int y = 0; y < GridSize; y += mul) {
            for (int z = 0; z < GridSize; z += mul) {

                int cubeindex = 0;

                corners[0] = ivec3(x, y, z);
                corners[1] = ivec3(x + mul, y, z);
                corners[2] = ivec3(x + mul, y, z + mul);
                corners[3] = ivec3(x, y, z + mul);
                corners[4] = ivec3(x, y + mul, z);
                corners[5] = ivec3(x + mul, y + mul, z);
                corners[6] = ivec3(x + mul, y + mul, z + mul);
                corners[7] = ivec3(x, y + mul, z + mul);

                for (int i = 0; i < corners.length; i++)
                    densities[i] = texelFetch(grid, ivec3(corners[i] * GridSize/pow(2.0,level)), level).r;
                    //densities[i] = texelFetch(grid, ivec3(corners[i]), level).r;

                //the |= operator performs a bitwise logical OR operation on integral operands
                if (densities[0] < ISO_LEVEL) cubeindex |= 1;
                if (densities[1] < ISO_LEVEL) cubeindex |= 2;
                if (densities[2] < ISO_LEVEL) cubeindex |= 4;
                if (densities[3] < ISO_LEVEL) cubeindex |= 8;
                if (densities[4] < ISO_LEVEL) cubeindex |= 16;
                if (densities[5] < ISO_LEVEL) cubeindex |= 32;
                if (densities[6] < ISO_LEVEL) cubeindex |= 64;
                if (densities[7] < ISO_LEVEL) cubeindex |= 128;
            
                //no triangles if it is surrounded by air or surrounded by blocks
                if (EDGES[cubeindex] == 0 || EDGES[cubeindex] == 255) continue;

                //find the vertices where the surface intersects the cube
                //the & operator performs a bitwise logical AND operation on integral operands
                if ((EDGES[cubeindex] & 1) == 1)
                    vertices[0] = interpolation(corners[0], corners[1], densities[0], densities[1]);
                if ((EDGES[cubeindex] & 2) == 2)
                    vertices[1] = interpolation(corners[1], corners[2], densities[1], densities[2]);
                if ((EDGES[cubeindex] & 4) == 4)
                    vertices[2] = interpolation(corners[2], corners[3], densities[2], densities[3]);
                if ((EDGES[cubeindex] & 8) == 8)
                    vertices[3] = interpolation(corners[3], corners[0], densities[3], densities[0]);
                if ((EDGES[cubeindex] & 16) == 16)
                    vertices[4] = interpolation(corners[4], corners[5], densities[4], densities[5]);
                if ((EDGES[cubeindex] & 32) == 32)
                    vertices[5] = interpolation(corners[5], corners[6], densities[5], densities[6]);
                if ((EDGES[cubeindex] & 64) == 64)
                    vertices[6] = interpolation(corners[6], corners[7], densities[6], densities[7]);
                if ((EDGES[cubeindex] & 128) == 128)
                    vertices[7] = interpolation(corners[7], corners[4], densities[7], densities[4]);
                if ((EDGES[cubeindex] & 256) == 256)
                    vertices[8] = interpolation(corners[0], corners[4], densities[0], densities[4]);
                if ((EDGES[cubeindex] & 512) == 512)
                    vertices[9] = interpolation(corners[1], corners[5], densities[1], densities[5]);
                if ((EDGES[cubeindex] & 1024) == 1024)
                    vertices[10] = interpolation(corners[2], corners[6], densities[2], densities[6]);
                if ((EDGES[cubeindex] & 2048) == 2048)
                    vertices[11] = interpolation(corners[3], corners[7], densities[3], densities[7]);
                
                for (int i = 0; TRIANGLES[cubeindex][i] != -1; i += 3) {
                    gl_Position = PVM * vec4(vertices[TRIANGLES[cubeindex][i+2]], 1);
                    EmitVertex();

                    gl_Position = PVM * vec4(vertices[TRIANGLES[cubeindex][i+1]], 1);
                    EmitVertex();

                    gl_Position = PVM * vec4(vertices[TRIANGLES[cubeindex][i]], 1);
                    EmitVertex();
                    
                    EndPrimitive();
                }
            }
        }
    }
    EndPrimitive(); 
}