

// LÖVE 片段着色器入口，必须叫 effect
vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
{
    // texcoord 与 gl_TexCoord[0].xy 等价
    vec2 uv = texcoord;

    float dist = distance(uv, vec2(0.5));               // 到中心的距离
    float glow = 1.0 - smoothstep(0.2, 0.5, dist);     // 产生光晕强度
    vec4 result = vec4(1.0, 0.2, 0.2, glow);           // 红色 + 透明度

    return result * color;   // 乘以传入的颜色乘子（默认白色）
}