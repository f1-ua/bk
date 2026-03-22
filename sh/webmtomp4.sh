#!/bin/bash

# --- 帮助信息函数 ---
show_help() {
    echo "================================================================"
    echo "         FFmpeg 媒体转换工具 - 极简/专业/全能脚本"
    echo "================================================================"
    echo "原理说明:"
    echo "  本脚本基于 FFmpeg，利用不同视频编码协议的压缩特性实现目标："
    echo "  - H.264 (AVC): 依靠硬件加速广泛，适合任何设备播放。"
    echo "  - H.265 (HEVC): 利用高效帧内预测，同画质下比H.264省一半空间。"
    echo "  - AV1: 下一代开放格式，压缩率最高，适合长期归档。"
    echo "  - CRF (恒定质量): 核心逻辑是'按需分配码率'，复杂画面多给，简单画面少给。"
    echo ""
    echo "使用方法:"
    echo "  ./media_tool.sh [输入文件] [模式]"
    echo ""
    echo "模式选项:"
    echo "  1  (兼容模式): 转为 H.264 MP4 (最快，兼容性最强)"
    echo "  2  (省空间模式): 转为 H.265 MP4 (画质极佳，体积减半)"
    echo "  3  (极致模式): 转为 AV1 MKV (最高压缩率，编码较慢)"
    echo "  4  (提取音频): 仅提取高质量 MP3 音频"
    echo "  5  (快速封装): 不重新编码，仅更换 MP4 容器 (秒速完成)"
    echo ""
    echo "示例:"
    echo "  ./media_tool.sh video.webm 2"
    echo "================================================================"
}

# 检查参数
if [ "$#" -ne 2 ]; then
    show_help
    exit 1
fi

INPUT="$1"
MODE="$2"
FILENAME="${INPUT%.*}"

case $MODE in
    1)
        echo "正在使用 H.264 (兼容模式) 转换..."
        ffmpeg -i "$INPUT" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 128k "${FILENAME}_h264.mp4"
        ;;
    2)
        echo "正在使用 H.265 (省空间模式) 转换..."
        ffmpeg -i "$INPUT" -c:v libx265 -preset slow -crf 24 -c:a aac -b:a 128k "${FILENAME}_h265.mp4"
        ;;
    3)
        echo "正在使用 AV1 (极致压缩模式) 转换..."
        ffmpeg -i "$INPUT" -c:v libsvtav1 -preset 6 -crf 30 -c:a opus -b:a 96k "${FILENAME}_av1.mkv"
        ;;
    4)
        echo "正在提取音频..."
        ffmpeg -i "$INPUT" -vn -c:a libmp3lame -q:a 2 "${FILENAME}.mp3"
        ;;
    5)
        echo "正在进行快速封装..."
        ffmpeg -i "$INPUT" -c copy "${FILENAME}_copy.mp4"
        ;;
    *)
        echo "错误: 无效模式！"
        show_help
        ;;
esac

echo "处理完成！"
