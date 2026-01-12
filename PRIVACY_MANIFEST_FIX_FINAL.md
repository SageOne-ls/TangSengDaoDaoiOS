# 隐私清单文件修复最终方案

## 问题描述

Apple App Store 审核拒绝（ITMS-91061），原因是以下第三方 SDK 缺少隐私清单文件（Privacy Manifest）：
- AFNetworking
- FMDB
- MBProgressHUD
- SDWebImage
- Starscream
- Toast

## 解决方案

### 1. 创建隐私清单文件

已为所有 6 个 SDK 创建了 `PrivacyInfo.xcprivacy` 文件：
- ✅ `Pods/AFNetworking/PrivacyInfo.xcprivacy`
- ✅ `Pods/FMDB/PrivacyInfo.xcprivacy`
- ✅ `Pods/MBProgressHUD/PrivacyInfo.xcprivacy`
- ✅ `Pods/SDWebImage/PrivacyInfo.xcprivacy`
- ✅ `Pods/Starscream/PrivacyInfo.xcprivacy`
- ✅ `Pods/Toast/PrivacyInfo.xcprivacy`

### 2. 添加构建脚本

在 `Podfile` 的 `post_install` hook 中添加了脚本，为每个 framework target 添加了 "Copy Privacy Manifest" 构建脚本阶段。该脚本会在 framework 构建完成后，将 `PrivacyInfo.xcprivacy` 文件复制到 framework bundle 的根目录。

## 关键要点

1. **文件位置**：`PrivacyInfo.xcprivacy` 必须位于 framework bundle 的根目录（与 framework 可执行文件同级）
2. **构建时机**：构建脚本在 framework 构建完成后运行，确保文件被正确复制
3. **文件路径**：脚本使用 `${PODS_ROOT}/<SDK_NAME>/PrivacyInfo.xcprivacy` 作为源文件路径

## 下一步操作

### 1. 完全清理构建缓存

```bash
# 清理 Xcode 构建缓存
./clean_build_cache.sh

# 或者在 Xcode 中：
# Product -> Clean Build Folder (Shift+Cmd+K)
```

### 2. 重新构建项目

在 Xcode 中：
1. 选择 Product -> Clean Build Folder (Shift+Cmd+K)
2. 重新构建项目 (Cmd+B)
3. **重要**：检查构建日志，确认看到 "✅ Copied PrivacyInfo.xcprivacy to <FrameworkName>.framework" 消息

### 3. 验证 framework bundle

构建后，验证 framework bundle 中是否包含隐私清单文件：

```bash
# 方法1：检查构建产物
find ~/Library/Developer/Xcode/DerivedData -name "AFNetworking.framework" -exec ls -la {}/PrivacyInfo.xcprivacy \;

# 方法2：在 Xcode 中
# 1. 构建项目
# 2. 在 Products 文件夹中找到 framework
# 3. 右键点击 framework -> "Show in Finder"
# 4. 检查 framework bundle 根目录是否有 PrivacyInfo.xcprivacy 文件
```

### 4. 归档并验证

1. 在 Xcode 中归档应用 (Product -> Archive)
2. 在 Organizer 中右键点击归档文件 -> "Show in Finder"
3. 检查 `.xcarchive/Products/Frameworks/` 目录中的每个 framework 是否包含 `PrivacyInfo.xcprivacy`
4. 验证所有 6 个 framework 都包含隐私清单文件

### 5. 上传新版本到 App Store Connect

1. 在 Xcode 中归档应用
2. 验证归档文件中包含所有 PrivacyInfo.xcprivacy 文件
3. 上传到 App Store Connect
4. 提交审核

## 验证清单

在提交审核前，请确认：

- [ ] 所有 6 个 SDK 的 PrivacyInfo.xcprivacy 文件都已创建
- [ ] 构建脚本已添加到所有 6 个 framework target
- [ ] 构建日志显示文件被成功复制
- [ ] 构建产物中的 framework bundle 包含 PrivacyInfo.xcprivacy
- [ ] 归档文件中的 framework bundle 包含 PrivacyInfo.xcprivacy

## 如果仍然被拒绝

如果 Apple 仍然报告缺少隐私清单文件，请检查：

1. **构建脚本执行**：检查构建日志，确认脚本是否执行
2. **文件路径**：确认 `${PODS_ROOT}` 变量是否正确解析
3. **构建时机**：确认脚本在 framework 构建完成后运行
4. **归档验证**：在提交前验证归档文件中的 framework 包含隐私清单文件

## 参考链接

- [Apple 第三方 SDK 要求](https://developer.apple.com/support/third-party-SDK-requirements)
- [隐私清单文件格式](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [ITMS-91061 错误说明](https://developer.apple.com/documentation/technotes/tn3151)

