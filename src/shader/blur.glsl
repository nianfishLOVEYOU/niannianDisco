
// LÖVE 里纹理统一使用 Image 类型
uniform Image tex;          // 传入的纹理
uniform vec2 screenSize;    // 屏幕尺寸（像素）

// 片段着色器入口，必须叫 effect，参数顺序不能改
vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
{
    // texcoord 已经是归一化坐标（0~1），等价于 gl_TexCoord[0].xy
    vec2 uv = texcoord;

    // 每个像素在 UV 空间的大小
    vec2 pixel = 1.0 / screenSize;

    vec4 result = vec4(0.0);

    // 简单高斯模糊（5×5 采样，权重 0.04）
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            // LÖVE 读取纹理的函数是 Texel，而不是 texture2D
            result += Texel(tex, uv + vec2(x, y) * pixel) * 0.04;
        }
    }

    // 乘以传入的颜色乘子（默认是白色），保持 LÖVE 的颜色混合机制
    return result * color;
}