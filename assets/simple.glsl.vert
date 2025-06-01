#version 460

layout(set=1, binding=0) uniform UBO {
    mat4 matMVP;
};

const vec2 positions[3] = vec2[](
    vec2(-0.5, -0.5),
    vec2(+0.5, -0.5),
    vec2(0.0, 0.5)
);

void main()
{
    gl_Position = matMVP * vec4(positions[gl_VertexIndex], 0, 1);
}