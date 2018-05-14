#version 440

/*
https://pastebin.com/DQ4Xjn7t
*/

layout(points) in;
layout(triangle_strip, max_vertices = 15) out;

/*
layout(std430, binding = 1) buffer edgesBuffer {
    int EDGES[];
};*/

layout(std430, binding = 2) buffer trianglesBuffer {
    int TRIANGLES[][16];
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

int EDGES[] = { 
    0x0, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c, 0x80c, 0x905, 0xa0f,
    0xb06, 0xc0a, 0xd03, 0xe09, 0xf00, 0x190, 0x99, 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c, 0x99c, 0x895,
    0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90, 0x230, 0x339, 0x33, 0x13a, 0x636, 0x73f, 0x435, 0x53c, 0xa3c,
    0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30, 0x3a0, 0x2a9, 0x1a3, 0xaa, 0x7a6, 0x6af, 0x5a5, 0x4ac,
    0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0, 0x460, 0x569, 0x663, 0x76a, 0x66, 0x16f, 0x265,
    0x36c, 0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60, 0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff,
    0x3f5, 0x2fc, 0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0, 0x650, 0x759, 0x453, 0x55a, 0x256,
    0x35f, 0x55, 0x15c, 0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950, 0x7c0, 0x6c9, 0x5c3, 0x4ca,
    0x3c6, 0x2cf, 0x1c5, 0xcc, 0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0, 0x8c0, 0x9c9, 0xac3,
    0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc, 0xcc, 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0, 0x950, 0x859,
    0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c, 0x15c, 0x55, 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650, 0xaf0,
    0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc, 0x2fc, 0x3f5, 0xff, 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
    0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c, 0x36c, 0x265, 0x16f, 0x66, 0x76a, 0x663, 0x569,
    0x460, 0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac, 0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa, 0x1a3,
    0x2a9, 0x3a0, 0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c, 0x53c, 0x435, 0x73f, 0x636, 0x13a,
    0x33, 0x339, 0x230, 0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c, 0x69c, 0x795, 0x49f, 0x596,
    0x29a, 0x393, 0x99, 0x190, 0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c, 0x70c, 0x605, 0x50f,
    0x406, 0x30a, 0x203, 0x109, 0x0 
};

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
                    gl_Position = vec4(vertices[TRIANGLES[cubeindex][i+2]], 0);
                    EmitVertex();

                    gl_Position = vec4(vertices[TRIANGLES[cubeindex][i+1]], 0);
                    EmitVertex();

                    gl_Position = vec4(vertices[TRIANGLES[cubeindex][i]], 0);
                    EmitVertex();
                }
            }
        }
    }
    EndPrimitive();    
}