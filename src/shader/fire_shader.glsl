// Love2D 只需要 fragment 部分
extern vec2 firePos;      // 火光中心（屏幕坐标，像素）
extern float radius;      // 影响半径
extern float time;         // 累计时间

vec4 effect( vec4 color, Image tex, vec2 texCoords, vec2 screenCoords )
{
    // 读取原始像素颜色
    vec4 src = Texel(tex, texCoords);

    // 与火光中心的距离（像素坐标）
    float d = distance(screenCoords, firePos);

    // 基础衰减（距离越远越暗）
    float atten = 1.0 - smoothstep(0.0, radius, d);

    // 产生不稳定的闪烁：使用正弦 + 噪声
    float flicker = 0.5 + 0.5 * sin(time * 8.0 + d * 0.1);
    // 进一步加入随机噪声（GLSL 1.2 没有内置噪声，使用伪随机）
    float rnd = fract(sin(dot(screenCoords, vec2(12.9898,78.233))) * 43758.5453;
    flicker = mix(flicker, rnd, 0.2);

    // 火光颜色（橙黄系）
    vec3 fireColor = vec3(1.0, 0.6, 0.2);

    // 最终光照强度
    float intensity = atten * flicker;

    // 将火光叠加到原始颜色（加法混合）
    vec3 result = src.rgb + fireColor * intensity;

    // 防止颜色溢出
    result = clamp(result, 0.0, 1.0);

    return vec4(result, src.a);
}