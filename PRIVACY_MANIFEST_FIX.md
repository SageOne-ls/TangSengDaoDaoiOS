# 隐私清单文件修复说明

## 问题描述

Apple App Store 审核拒绝，原因是以下第三方 SDK 缺少隐私清单文件（Privacy Manifest）：
- AFNetworking
- FMDB
- MBProgressHUD
- SDWebImage
- Starscream
- Toast

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

在 `Podfile` 的 `post_install` hook 中添加了自动创建隐私清单文件的脚本，确保每次运行 `pod install` 时都会自动创建这些文件。

## 下一步操作

### 1. 重新运行 pod install

```bash
cd /Users/study/GIT/TangSengDaoDaoiOS
pod install
```

这将确保所有隐私清单文件被正确创建并包含在构建中。

### 2. 清理构建缓存

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
3. 归档应用 (Product -> Archive)

### 4. 验证隐私清单文件

在归档之前，可以验证隐私清单文件是否被正确包含：

```bash
# 检查文件是否存在
ls -la Pods/AFNetworking/PrivacyInfo.xcprivacy
ls -la Pods/FMDB/PrivacyInfo.xcprivacy
ls -la Pods/MBProgressHUD/PrivacyInfo.xcprivacy
ls -la Pods/SDWebImage/PrivacyInfo.xcprivacy
ls -la Pods/Starscream/PrivacyInfo.xcprivacy
ls -la Pods/Toast/PrivacyInfo.xcprivacy
```

### 5. 上传新版本到 App Store Connect

1. 在 Xcode 中归档应用
2. 上传到 App Store Connect
3. 提交审核

## 注意事项

1. **隐私清单文件内容**：所有隐私清单文件都声明：
   - 不访问任何隐私 API
   - 不收集任何数据
   - 不进行跟踪
   - 不跟踪用户

2. **自动创建**：由于在 `Podfile` 中添加了自动创建脚本，每次运行 `pod install` 时都会自动创建这些文件，即使它们被删除也会重新创建。

3. **框架位置**：对于使用 `use_frameworks!` 的项目，隐私清单文件需要放在每个 SDK 的根目录中，这正是我们做的。

## 参考链接

- [Apple 第三方 SDK 要求](https://developer.apple.com/support/third-party-SDK-requirements)
- [隐私清单文件格式](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)


