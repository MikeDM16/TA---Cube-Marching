#version 440

/*
https://github.com/jdupuy/marchingCube/
*/

layout(points) in;
layout(triangle_strip, max_vertices = 15) out;

layout(std430, binding = 3) buffer connectBuffer {
    int uEdgeConnectList[256][20];
};

layout(std430, binding = 4) buffer facesBuffer {
    int uCaseToNumPolys[64][4];
};

uniform mat4 PVM;
uniform sampler3D grid;
uniform int GridSize;
uniform int level = 0;

uniform int uCase = 2;

void main()
{
    // compute the edges of the voxel
    float voxelHalfSize = 0.5;
    float xmin = -voxelHalfSize;
    float xmax = +voxelHalfSize;
    float ymin = -voxelHalfSize;
    float ymax = +voxelHalfSize;
    float zmin = -voxelHalfSize;
    float zmax = +voxelHalfSize;

    // follow tables convention (GPU Gems3)
    vec3 voxelVertices[8];
    voxelVertices[0] = vec3(xmax, ymin, zmin);
    voxelVertices[1] = vec3(xmax, ymin, zmax);
    voxelVertices[2] = vec3(xmax, ymax, zmax);
    voxelVertices[3] = vec3(xmax, ymax, zmin);
    voxelVertices[4] = vec3(xmin, ymin, zmin);
    voxelVertices[5] = vec3(xmin, ymin, zmax);
    voxelVertices[6] = vec3(xmin, ymax, zmax);
    voxelVertices[7] = vec3(xmin, ymax, zmin);

    // emit vertices using the marching cube tables
    int numPolys = uCaseToNumPolys[uCase/4][uCase%4];
    int i = 0;
    int edgeList, idx1, idx2;
    vec3 vertex;
    while(i<numPolys) {
        int offset = uCase*5 + i;
        edgeList = uEdgeConnectList[offset/4][offset%4];
        //edgeList = texelFetch(sEdgeConnectList, offset/4)[offset%4];
        idx1 = edgeList    & 0x7;
        idx2 = edgeList>>3 & 0x7;
        vertex = 0.5 * voxelVertices[idx1]
               + 0.5 * voxelVertices[idx2];
        gl_Position = PVM * vec4(vertex,1.0);
        EmitVertex();
        idx1 = edgeList>>6 & 0x7;
        idx2 = edgeList>>9 & 0x7;
        vertex = 0.5 * voxelVertices[idx1]
               + 0.5 * voxelVertices[idx2];
        gl_Position = PVM * vec4(vertex,1.0);
        EmitVertex();
        idx1 = edgeList>>12 & 0x7;
        idx2 = edgeList>>15 & 0x7;
        vertex = 0.5 * voxelVertices[idx1]
               + 0.5 * voxelVertices[idx2];
        gl_Position = PVM * vec4(vertex,1.0);
        EmitVertex();
        EndPrimitive();
        ++i;
    }
}