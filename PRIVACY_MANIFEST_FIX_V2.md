# 隐私清单文件修复说明 V2

## 问题描述

Apple App Store 审核拒绝（ITMS-91061），原因是以下第三方 SDK 缺少隐私清单文件（Privacy Manifest）：
- AFNetworking
- FMDB
- MBProgressHUD
- SDWebImage
- Starscream
- Toast

## Apple 官方要求

根据 [Apple 第三方 SDK 要求文档](https://developer.apple.com/support/third-party-SDK-requirements)：

1. **文件位置**：`PrivacyInfo.xcprivacy` 必须位于 framework bundle 的根目录（与 framework 可执行文件同级）
2. **文件格式**：必须是有效的 plist 格式
3. **必需字段**：
   - `NSPrivacyAccessedAPITypes` - 访问的隐私 API 类型
   - `NSPrivacyCollectedDataTypes` - 收集的数据类型
   - `NSPrivacyTrackingDomains` - 跟踪域名
   - `NSPrivacyTracking` - 是否进行跟踪

## 已完成的修复

### 1. 创建了隐私清单文件

已为以下 SDK 创建了 `PrivacyInfo.xcprivacy` 文件：
- ✅ `Pods/AFNetworking/PrivacyInfo.xcprivacy`
- ✅ `Pods/FMDB/PrivacyInfo.xcprivacy`
- ✅ `Pods/MBProgressHUD/PrivacyInfo.xcprivacy`
- ✅ `Pods/SDWebImage/PrivacyInfo.xcprivacy`
- ✅ `Pods/Starscream/PrivacyInfo.xcprivacy`
- ✅ `Pods/Toast/PrivacyInfo.xcprivacy`

### 2. 更新了 Podfile

在 `Podfile` 的 `post_install` hook 中添加了脚本：
- 自动创建隐私清单文件
- 将文件添加到每个 framework target 的资源构建阶段
- 确保文件被复制到 framework bundle 根目录

## 重要说明

### 对于使用 `use_frameworks!` 的项目

当使用 `use_frameworks!` 时，CocoaPods 会将依赖编译为动态框架。隐私清单文件需要：
1. 位于 Pod 的源代码目录中
2. 添加到 framework target 的资源构建阶段
3. 在构建时被复制到 framework bundle 的根目录

### 验证文件是否被正确包含

构建后，可以通过以下方式验证：

```bash
# 检查 framework 中是否包含 PrivacyInfo.xcprivacy
find ~/Library/Developer/Xcode/DerivedData -name "*.framework" -path "*/AFNetworking.framework" -exec ls -la {}/PrivacyInfo.xcprivacy \;
```

或者在 Xcode 中：
1. 构建项目
2. 在 Products 文件夹中找到 framework
3. 右键点击 framework -> "Show in Finder"
4. 检查 framework bundle 根目录是否有 `PrivacyInfo.xcprivacy` 文件

## 下一步操作

### 1. 重新运行 pod install

```bash
cd /Users/study/GIT/TangSengDaoDaoiOS
pod install
```

### 2. 完全清理构建缓存

```bash
# 清理 Xcode 构建缓存
./clean_build_cache.sh

# 或者在 Xcode 中：
# Product -> Clean Build Folder (Shift+Cmd+K)
```

### 3. 重新构建项目

在 Xcode 中：
1. 选择 Product -> Clean Build Folder (Shift+Cmd+K)
2. 重新构建项目 (Cmd+B)
3. **重要**：验证 framework 中是否包含 PrivacyInfo.xcprivacy
4. 归档应用 (Product -> Archive)

### 4. 验证 framework bundle

在归档之前，验证 framework bundle 中是否包含隐私清单文件：

```bash
# 方法1：检查构建产物
find ~/Library/Developer/Xcode/DerivedData -name "AFNetworking.framework" -exec ls -la {}/PrivacyInfo.xcprivacy \;

# 方法2：检查归档文件
# 在 Xcode Organizer 中，右键点击归档文件 -> "Show in Finder"
# 然后检查 .xcarchive/Products/Frameworks/ 目录
```

### 5. 上传新版本到 App Store Connect

1. 在 Xcode 中归档应用
2. 验证归档文件中包含所有 PrivacyInfo.xcprivacy 文件
3. 上传到 App Store Connect
4. 提交审核

## 如果仍然被拒绝

如果 Apple 仍然报告缺少隐私清单文件，请检查：

1. **文件位置**：确保文件在 framework bundle 根目录，而不是子目录
2. **文件格式**：确保 plist 格式正确，没有语法错误
3. **构建配置**：确保文件被添加到 Resources 构建阶段
4. **归档验证**：在提交前验证归档文件中的 framework 包含隐私清单文件

## 参考链接

- [Apple 第三方 SDK 要求](https://developer.apple.com/support/third-party-SDK-requirements)
- [隐私清单文件格式](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [ITMS-91061 错误说明](https://developer.apple.com/documentation/technotes/tn3151)

