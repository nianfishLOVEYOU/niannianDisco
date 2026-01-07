-- main.lua
local ffi = require "ffi"
local love = love

local Mp3Image ={}

-- 1️⃣ 加载 TagLib 动态库
local taglib = ffi.load("tag")   -- Windows: "tag.dll"；Linux/macOS: "libtag.so" / "libtag.dylib"


-- 2️⃣ 声明需要使用的 C 接口（仅列出本例所需的函数/结构体）
ffi.cdef[[
// 基本类型
typedef struct TagLib_File TagLib_File;
typedef struct TagLib_AudioProperties TagLib_AudioProperties;
typedef struct TagLib_Tag TagLib_Tag;
typedef struct TagLib_ID3v2_Tag TagLib_ID3v2_Tag;
typedef struct TagLib_Picture Frame_Picture;

// 文件打开/关闭
TagLib_File* TagLib_File_create(const char *filename);
void TagLib_File_free(TagLib_File *file);

// 获取标签
TagLib_Tag* TagLib_File_tag(TagLib_File *file);
TagLib_ID3v2_Tag* TagLib_Tag_ID3v2(TagLib_Tag *tag);

// 读取图片帧（APIC）
unsigned int TagLib_ID3v2_Tag_pictureCount(TagLib_ID3v2_Tag *tag);
Frame_Picture* TagLib_ID3v2_Tag_picture(TagLib_ID3v2_Tag *tag, unsigned int index);

// 图片帧成员
const unsigned char* Frame_Picture_data(Frame_Picture *pic);
unsigned int Frame_Picture_dataSize(Frame_Picture *pic);
const char* Frame_Picture_mimeType(Frame_Picture *pic);
int Frame_Picture_type(Frame_Picture *pic);   // 0=Other, 3=Cover(front) 等

// 释放图片帧
void Frame_Picture_free(Frame_Picture *pic);
]]

-- 3️⃣ 辅助函数：把二进制数据写入临时文件并返回 Image 对象
function Mp3Image:loadCoverFromMP3(mp3Path)
    local file = taglib.TagLib_File_create(mp3Path)
    if file == nil then return nil, "无法打开文件" end

    local tag = taglib.TagLib_File_tag(file)
    if tag == nil then
        taglib.TagLib_File_free(file)
        return nil, "没有标签"
    end

    local id3v2 = taglib.TagLib_Tag_ID3v2(tag)
    if id3v2 == nil then
        taglib.TagLib_File_free(file)
        return nil, "没有 ID3v2"
    end

    local picCount = taglib.TagLib_ID3v2_Tag_pictureCount(id3v2)
    if picCount == 0 then
        taglib.TagLib_File_free(file)
        return nil, "没有封面图片"
    end

    -- 取第一张封面（type==3 为 front cover，若想筛选可遍历全部）
    local pic = nil
    for i = 0, picCount - 1 do
        local p = taglib.TagLib_ID3v2_Tag_picture(id3v2, i)
        if p ~= nil and taglib.Frame_Picture_type(p) == 3 then
            pic = p
            break
        end
        taglib.Frame_Picture_free(p)
    end

    if pic == nil then
        taglib.TagLib_File_free(file)
        return nil, "未找到 front cover"
    end

    local dataPtr  = taglib.Frame_Picture_data(pic)
    local dataSize = tonumber(taglib.Frame_Picture_dataSize(pic))
    local mime     = ffi.string(taglib.Frame_Picture_mimeType(pic))

    -- 将二进制写入临时文件（Love2D 只能从文件或 ImageData 加载）
    local tmpPath = os.tmpname() .. (mime:find("png") and ".png" or ".jpg")
    local f = io.open(tmpPath, "wb")
    f:write(ffi.string(dataPtr, dataSize))
    f:close()

    -- 读取为 Image 对象
    local img = love.graphics.newImage(tmpPath)

    -- 清理
    taglib.Frame_Picture_free(pic)
    taglib.TagLib_File_free(file)

    return img, nil, tmpPath   -- 返回临时文件路径，后面可自行删除
end


-- 4️⃣ 示例使用
local coverImg, err, tmpFile
local function test()
    local mp3Path = "assets/music/example.mp3"   -- 你的 MP3 文件路径
    coverImg, err, tmpFile = loadCoverFromMP3(mp3Path)
    if not coverImg then
        print("读取封面失败:", err)
    else
        print("封面已加载，临时文件:", tmpFile)
    end
    
    --下一步打印
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(coverImg, 100, 100)   -- 任意位置绘制
    if tmpFile then os.remove(tmpFile) end
end

