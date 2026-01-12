# 如何检查打包后的 IPA 是否包含隐私清单文件

## 方法 1: 使用检查脚本（推荐）

我们提供了一个自动化检查脚本 `check_privacy_manifests.sh`。

### 检查构建后的 Framework

```bash
./check_privacy_manifests.sh build
```

这会检查 Xcode DerivedData 中构建后的 framework bundle。

### 检查 IPA 文件

```bash
./check_privacy_manifests.sh ipa /path/to/YourApp.ipa
```

例如：
```bash
./check_privacy_manifests.sh ipa ~/Desktop/ZoomT.ipa
```

### 同时检查构建和 IPA

```bash
./check_privacy_manifests.sh all ~/Desktop/ZoomT.ipa
```

## 方法 2: 手动检查构建后的 Framework

### 步骤 1: 找到 DerivedData 目录

```bash
# 打开 DerivedData 目录
open ~/Library/Developer/Xcode/DerivedData
```

### 步骤 2: 查找项目目录

找到以 `TangSengDaoDaoiOS` 开头的目录。

### 步骤 3: 检查 Framework

在终端中运行：

```bash
# 查找所有 framework
find ~/Library/Developer/Xcode/DerivedData/TangSengDaoDaoiOS-*/Build/Products -name "*.framework" -type d

# 检查特定 SDK 的隐私清单文件
ls -la ~/Library/Developer/Xcode/DerivedData/TangSengDaoDaoiOS-*/Build/Products/*/AFNetworking.framework/PrivacyInfo.xcprivacy
ls -la ~/Library/Developer/Xcode/DerivedData/TangSengDaoDaoiOS-*/Build/Products/*/FMDB.framework/PrivacyInfo.xcprivacy
ls -la ~/Library/Developer/Xcode/DerivedData/TangSengDaoDaoiOS-*/Build/Products/*/MBProgressHUD.framework/PrivacyInfo.xcprivacy
ls -la ~/Library/Developer/Xcode/DerivedData/TangSengDaoDaoiOS-*/Build/Products/*/SDWebImage.framework/PrivacyInfo.xcprivacy
ls -la ~/Library/Developer/Xcode/DerivedData/TangSengDaoDaoiOS-*/Build/Products/*/Starscream.framework/PrivacyInfo.xcprivacy
ls -la ~/Library/Developer/Xcode/DerivedData/TangSengDaoDaoiOS-*/Build/Products/*/Toast.framework/PrivacyInfo.xcprivacy
```

## 方法 3: 手动检查 IPA 文件

### 步骤 1: 解压 IPA 文件

```bash
# 创建临时目录
mkdir -p /tmp/ipa_check
cd /tmp/ipa_check

# 解压 IPA（替换为你的 IPA 路径）
unzip ~/Desktop/YourApp.ipa
```

### 步骤 2: 查找 Framework 目录

```bash
# 查找 .app 目录
find Payload -name "*.app" -type d

# 进入 Frameworks 目录
cd Payload/*.app/Frameworks
```

### 步骤 3: 检查隐私清单文件

```bash
# 列出所有 framework
ls -la

# 检查每个 framework 是否包含 PrivacyInfo.xcprivacy
for framework in *.framework; do
    echo "检查 $framework..."
    if [ -f "$framework/PrivacyInfo.xcprivacy" ]; then
        echo "  ✅ 找到 PrivacyInfo.xcprivacy"
        ls -lh "$framework/PrivacyInfo.xcprivacy"
    else
        echo "  ❌ 缺少 PrivacyInfo.xcprivacy"
    fi
done
```

### 步骤 4: 检查特定 SDK

```bash
# 检查所有 6 个 SDK
ls -la AFNetworking.framework/PrivacyInfo.xcprivacy
ls -la FMDB.framework/PrivacyInfo.xcprivacy
ls -la MBProgressHUD.framework/PrivacyInfo.xcprivacy
ls -la SDWebImage.framework/PrivacyInfo.xcprivacy
ls -la Starscream.framework/PrivacyInfo.xcprivacy
ls -la Toast.framework/PrivacyInfo.xcprivacy
```

### 步骤 5: 查看文件内容（可选）

```bash
# 查看隐私清单文件内容
cat AFNetworking.framework/PrivacyInfo.xcprivacy
```

### 步骤 6: 清理临时文件

```bash
cd ~
rm -rf /tmp/ipa_check
```

## 方法 4: 使用 Xcode 检查

### 步骤 1: 在 Xcode 中构建项目

1. 打开项目
2. 选择 Product -> Archive
3. 等待构建完成

### 步骤 2: 查看 Archive

1. 在 Organizer 窗口中选择 Archive
2. 右键点击 Archive -> Show in Finder
3. 右键点击 .xcarchive 文件 -> Show Package Contents
4. 导航到 `Products/Applications/YourApp.app/Frameworks/`
5. 检查每个 framework 是否包含 `PrivacyInfo.xcprivacy`

## 方法 5: 使用命令行快速检查

### 一键检查所有 Framework

```bash
# 检查构建后的 framework
for sdk in AFNetworking FMDB MBProgressHUD SDWebImage Starscream Toast; do
    echo "检查 $sdk..."
    find ~/Library/Developer/Xcode/DerivedData -name "${sdk}.framework" -type d -exec ls -la {}/PrivacyInfo.xcprivacy \; 2>&1 | head -1
done
```

### 检查 IPA 中的所有 Framework

```bash
# 替换为你的 IPA 路径
IPA_PATH="~/Desktop/YourApp.ipa"
TEMP_DIR=$(mktemp -d)
unzip -q "$IPA_PATH" -d "$TEMP_DIR"
find "$TEMP_DIR/Payload" -name "*.framework" -type d | while read framework; do
    framework_name=$(basename "$framework" .framework)
    if [ -f "$framework/PrivacyInfo.xcprivacy" ]; then
        echo "✅ $framework_name.framework"
    else
        echo "❌ $framework_name.framework - 缺少隐私清单"
    fi
done
rm -rf "$TEMP_DIR"
```

## 验证清单

在提交到 App Store 之前，确保：

- [ ] 所有 6 个 SDK 的 framework bundle 中都包含 `PrivacyInfo.xcprivacy`
- [ ] 文件位于 framework bundle 的根目录（与可执行文件同级）
- [ ] 文件格式正确（有效的 plist XML）
- [ ] 文件大小不为 0
- [ ] IPA 文件中的 framework 也包含隐私清单文件

## 常见问题

### Q: 构建后的 framework 中有文件，但 IPA 中没有？

**A:** 可能是构建脚本没有正确执行，或者文件没有被正确复制到 framework bundle。检查：
1. 构建日志中是否有脚本执行的消息
2. 构建脚本是否正确添加到所有 target
3. 文件路径是否正确

### Q: 如何确认文件在正确的位置？

**A:** `PrivacyInfo.xcprivacy` 必须位于 framework bundle 的根目录，与 framework 可执行文件同级。例如：
```
AFNetworking.framework/
├── AFNetworking (可执行文件)
├── PrivacyInfo.xcprivacy ✅ (正确位置)
├── Headers/
└── Resources/
```

### Q: 检查脚本显示文件存在，但 Apple 审核仍然拒绝？

**A:** 可能的原因：
1. 文件格式不正确
2. 文件内容不符合 Apple 要求
3. 文件没有被正确签名
4. 需要检查文件的实际内容

## 参考

- [Apple 第三方 SDK 要求](https://developer.apple.com/support/third-party-SDK-requirements)
- [隐私清单文件格式](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)

