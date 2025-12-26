#!/bin/bash
# 清理Xcode构建缓存，解决启动图不生效的问题

echo "正在清理Xcode构建缓存..."

# 1. 清理DerivedData
echo "1. 清理DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 2. 清理项目构建目录
echo "2. 清理项目构建目录..."
cd "$(dirname "$0")"
rm -rf build/
rm -rf TangSengDaoDaoiOS.xcodeproj/xcuserdata/
rm -rf TangSengDaoDaoiOS.xcodeproj/project.xcworkspace/xcuserdata/

# 3. 清理模块缓存
echo "3. 清理模块缓存..."
find . -name "*.xcuserstate" -delete
find . -name "*.xcworkspace" -exec rm -rf {}/xcuserdata/ \;

# 4. 清理CocoaPods缓存（如果使用）
if [ -f "Podfile" ]; then
    echo "4. 清理CocoaPods缓存..."
    pod cache clean --all 2>/dev/null || true
fi

echo ""
echo "✅ 构建缓存清理完成！"
echo ""
echo "请执行以下步骤："
echo "1. 在Xcode中：Product -> Clean Build Folder (Shift+Cmd+K)"
echo "2. 完全退出Xcode"
echo "3. 重新打开Xcode项目"
echo "4. 重新构建项目 (Cmd+B)"
echo "5. 运行应用 (Cmd+R)"
echo ""
echo "如果问题仍然存在，请检查："
echo "- LaunchScreen.storyboard 中的图片资源名称是否为 'launch'"
echo "- Assets.xcassets/launch.imageset/ 中的图片是否正确"
echo "- Info.plist 中的 UILaunchStoryboardName 是否为 'LaunchScreen'"


