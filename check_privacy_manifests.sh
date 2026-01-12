#!/bin/bash

# 检查隐私清单文件的脚本
# 使用方法：
#   1. 检查构建后的 framework: ./check_privacy_manifests.sh build
#   2. 检查 IPA 文件: ./check_privacy_manifests.sh ipa /path/to/YourApp.ipa
#   3. 检查所有: ./check_privacy_manifests.sh all

# 需要检查的 SDK 列表
SDK_NAMES=("AFNetworking" "FMDB" "MBProgressHUD" "SDWebImage" "Starscream" "Toast")

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_build_frameworks() {
    echo "🔍 检查构建后的 Framework Bundle..."
    echo "=========================================="
    
    # 查找 DerivedData 目录
    DERIVED_DATA_DIR="$HOME/Library/Developer/Xcode/DerivedData"
    
    if [ ! -d "$DERIVED_DATA_DIR" ]; then
        echo "❌ 未找到 DerivedData 目录: $DERIVED_DATA_DIR"
        return 1
    fi
    
    # 查找项目相关的 DerivedData
    PROJECT_DIR=$(find "$DERIVED_DATA_DIR" -name "TangSengDaoDaoiOS*" -type d | head -1)
    
    if [ -z "$PROJECT_DIR" ]; then
        echo "⚠️  未找到项目相关的 DerivedData，请先构建项目"
        return 1
    fi
    
    echo "📁 项目 DerivedData: $PROJECT_DIR"
    echo ""
    
    local found_count=0
    local missing_count=0
    
    for sdk in "${SDK_NAMES[@]}"; do
        # 查找 framework
        FRAMEWORK_PATH=$(find "$PROJECT_DIR" -name "${sdk}.framework" -type d | head -1)
        
        if [ -z "$FRAMEWORK_PATH" ]; then
            echo -e "${YELLOW}⚠️  ${sdk}.framework 未找到${NC}"
            continue
        fi
        
        # Check both possible locations: root and Contents/Resources
        PRIVACY_FILE_ROOT="${FRAMEWORK_PATH}/PrivacyInfo.xcprivacy"
        PRIVACY_FILE_RESOURCES="${FRAMEWORK_PATH}/Contents/Resources/PrivacyInfo.xcprivacy"
        
        if [ -f "$PRIVACY_FILE_ROOT" ]; then
            PRIVACY_FILE="$PRIVACY_FILE_ROOT"
            LOCATION="framework root"
        elif [ -f "$PRIVACY_FILE_RESOURCES" ]; then
            PRIVACY_FILE="$PRIVACY_FILE_RESOURCES"
            LOCATION="Contents/Resources"
        else
            PRIVACY_FILE=""
        fi
        
        if [ -n "$PRIVACY_FILE" ] && [ -f "$PRIVACY_FILE" ]; then
            echo -e "${GREEN}✅ ${sdk}.framework${NC}"
            echo "   路径: $FRAMEWORK_PATH"
            echo "   位置: $LOCATION"
            echo "   文件大小: $(ls -lh "$PRIVACY_FILE" | awk '{print $5}')"
            found_count=$((found_count + 1))
        else
            echo -e "${RED}❌ ${sdk}.framework - 缺少 PrivacyInfo.xcprivacy${NC}"
            echo "   路径: $FRAMEWORK_PATH"
            missing_count=$((missing_count + 1))
        fi
        echo ""
    done
    
    echo "=========================================="
    echo "📊 统计:"
    echo "   ✅ 找到: $found_count"
    echo "   ❌ 缺失: $missing_count"
    echo "   📦 总计: ${#SDK_NAMES[@]}"
    
    if [ $missing_count -eq 0 ]; then
        echo -e "\n${GREEN}🎉 所有 Framework 都包含隐私清单文件！${NC}"
        return 0
    else
        echo -e "\n${RED}⚠️  有 $missing_count 个 Framework 缺少隐私清单文件${NC}"
        return 1
    fi
}

check_ipa_file() {
    local IPA_PATH="$1"
    
    if [ -z "$IPA_PATH" ]; then
        echo "❌ 请提供 IPA 文件路径"
        echo "使用方法: $0 ipa /path/to/YourApp.ipa"
        return 1
    fi
    
    if [ ! -f "$IPA_PATH" ]; then
        echo "❌ IPA 文件不存在: $IPA_PATH"
        return 1
    fi
    
    echo "🔍 检查 IPA 文件: $IPA_PATH"
    echo "=========================================="
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    echo "📁 临时解压目录: $TEMP_DIR"
    
    # 解压 IPA
    echo "📦 解压 IPA 文件..."
    unzip -q "$IPA_PATH" -d "$TEMP_DIR"
    
    if [ $? -ne 0 ]; then
        echo "❌ 解压 IPA 文件失败"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # 查找 Payload 目录
    PAYLOAD_DIR="$TEMP_DIR/Payload"
    if [ ! -d "$PAYLOAD_DIR" ]; then
        echo "❌ 未找到 Payload 目录"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # 查找 .app 目录
    APP_DIR=$(find "$PAYLOAD_DIR" -name "*.app" -type d | head -1)
    if [ -z "$APP_DIR" ]; then
        echo "❌ 未找到 .app 目录"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    echo "📱 App 目录: $APP_DIR"
    echo ""
    
    # 查找 Frameworks 目录
    FRAMEWORKS_DIR="$APP_DIR/Frameworks"
    if [ ! -d "$FRAMEWORKS_DIR" ]; then
        echo "⚠️  未找到 Frameworks 目录"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    echo "🔍 检查 Frameworks 目录中的隐私清单文件..."
    echo ""
    
    local found_count=0
    local missing_count=0
    
    for sdk in "${SDK_NAMES[@]}"; do
        FRAMEWORK_PATH="$FRAMEWORKS_DIR/${sdk}.framework"
        PRIVACY_FILE_ROOT="$FRAMEWORK_PATH/PrivacyInfo.xcprivacy"
        PRIVACY_FILE_RESOURCES="$FRAMEWORK_PATH/Contents/Resources/PrivacyInfo.xcprivacy"
        
        if [ -d "$FRAMEWORK_PATH" ]; then
            # Check both possible locations
            if [ -f "$PRIVACY_FILE_ROOT" ]; then
                PRIVACY_FILE="$PRIVACY_FILE_ROOT"
                LOCATION="framework root"
            elif [ -f "$PRIVACY_FILE_RESOURCES" ]; then
                PRIVACY_FILE="$PRIVACY_FILE_RESOURCES"
                LOCATION="Contents/Resources"
            else
                PRIVACY_FILE=""
            fi
            
            if [ -n "$PRIVACY_FILE" ] && [ -f "$PRIVACY_FILE" ]; then
                echo -e "${GREEN}✅ ${sdk}.framework${NC}"
                echo "   位置: $LOCATION"
                echo "   文件大小: $(ls -lh "$PRIVACY_FILE" | awk '{print $5}')"
                # 显示文件内容的前几行
                echo "   内容预览:"
                head -3 "$PRIVACY_FILE" | sed 's/^/      /'
                found_count=$((found_count + 1))
            else
                echo -e "${RED}❌ ${sdk}.framework - 缺少 PrivacyInfo.xcprivacy${NC}"
                missing_count=$((missing_count + 1))
            fi
        else
            echo -e "${YELLOW}⚠️  ${sdk}.framework 未在 IPA 中找到${NC}"
        fi
        echo ""
    done
    
    # 检查所有 framework（不仅仅是列表中的）
    echo "🔍 检查所有 Framework 的隐私清单文件..."
    echo ""
    ALL_FRAMEWORKS=$(find "$FRAMEWORKS_DIR" -name "*.framework" -type d)
    TOTAL_FRAMEWORKS=$(echo "$ALL_FRAMEWORKS" | wc -l | tr -d ' ')
    FRAMEWORKS_WITH_PRIVACY=0
    FRAMEWORKS_WITHOUT_PRIVACY=0
    
    while IFS= read -r framework; do
        if [ -n "$framework" ]; then
            framework_name=$(basename "$framework" .framework)
            privacy_file_root="$framework/PrivacyInfo.xcprivacy"
            privacy_file_resources="$framework/Contents/Resources/PrivacyInfo.xcprivacy"
            
            # Check both possible locations
            if [ -f "$privacy_file_root" ] || [ -f "$privacy_file_resources" ]; then
                FRAMEWORKS_WITH_PRIVACY=$((FRAMEWORKS_WITH_PRIVACY + 1))
            else
                FRAMEWORKS_WITHOUT_PRIVACY=$((FRAMEWORKS_WITHOUT_PRIVACY + 1))
                echo -e "${YELLOW}⚠️  ${framework_name}.framework 缺少隐私清单文件${NC}"
            fi
        fi
    done <<< "$ALL_FRAMEWORKS"
    
    echo "=========================================="
    echo "📊 统计:"
    echo "   目标 SDK:"
    echo "     ✅ 找到: $found_count"
    echo "     ❌ 缺失: $missing_count"
    echo "   所有 Framework:"
    echo "     ✅ 有隐私清单: $FRAMEWORKS_WITH_PRIVACY"
    echo "     ❌ 缺少隐私清单: $FRAMEWORKS_WITHOUT_PRIVACY"
    echo "     📦 总计: $TOTAL_FRAMEWORKS"
    
    # 清理临时目录
    rm -rf "$TEMP_DIR"
    
    if [ $missing_count -eq 0 ] && [ $FRAMEWORKS_WITHOUT_PRIVACY -eq 0 ]; then
        echo -e "\n${GREEN}🎉 所有 Framework 都包含隐私清单文件！${NC}"
        return 0
    else
        echo -e "\n${RED}⚠️  有 Framework 缺少隐私清单文件${NC}"
        return 1
    fi
}

# 主函数
case "$1" in
    build)
        check_build_frameworks
        ;;
    ipa)
        check_ipa_file "$2"
        ;;
    all)
        check_build_frameworks
        echo ""
        echo "=========================================="
        echo ""
        if [ -n "$2" ]; then
            check_ipa_file "$2"
        else
            echo "💡 提示: 使用 './check_privacy_manifests.sh all /path/to/YourApp.ipa' 同时检查 IPA 文件"
        fi
        ;;
    *)
        echo "使用方法:"
        echo "  $0 build                    - 检查构建后的 Framework"
        echo "  $0 ipa <ipa_path>           - 检查 IPA 文件"
        echo "  $0 all [ipa_path]           - 检查所有（构建 + IPA）"
        echo ""
        echo "示例:"
        echo "  $0 build"
        echo "  $0 ipa ~/Desktop/YourApp.ipa"
        echo "  $0 all ~/Desktop/YourApp.ipa"
        exit 1
        ;;
esac

