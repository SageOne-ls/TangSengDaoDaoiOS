# 隐私清单文件合规性检查清单

## Apple 第三方 SDK 要求

根据 Apple 的第三方 SDK 要求（ITMS-91061），所有常用的第三方 SDK 必须包含隐私清单文件（Privacy Manifest）。

参考文档：<https://developer.apple.com/support/third-party-SDK-requirements>

## 已处理的 SDK 列表

以下 6 个 SDK 已创建并配置隐私清单文件：

1. ✅ **AFNetworking** - `Pods/AFNetworking/PrivacyInfo.xcprivacy`
2. ✅ **FMDB** - `Pods/FMDB/PrivacyInfo.xcprivacy`
3. ✅ **MBProgressHUD** - `Pods/MBProgressHUD/PrivacyInfo.xcprivacy`
4. ✅ **SDWebImage** - `Pods/SDWebImage/PrivacyInfo.xcprivacy`
5. ✅ **Starscream** - `Pods/Starscream/PrivacyInfo.xcprivacy`
6. ✅ **Toast** - `Pods/Toast/PrivacyInfo.xcprivacy`

## 隐私清单文件内容

所有隐私清单文件都包含以下声明：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
 <key>NSPrivacyAccessedAPITypes</key>
 <array/>
 <key>NSPrivacyCollectedDataTypes</key>
 <array/>
 <key>NSPrivacyTrackingDomains</key>
 <array/>
 <key>NSPrivacyTracking</key>
 <false/>
</dict>
</plist>
```

**声明内容**：

- 不访问任何隐私 API
- 不收集任何数据
- 不进行跟踪
- 不跟踪用户

## 构建脚本配置

### Podfile 配置

在 `Podfile` 的 `post_install` hook 中：

1. **自动创建隐私清单文件**：为每个 SDK 在 `Pods/<SDK_NAME>/PrivacyInfo.xcprivacy` 创建文件
2. **添加构建脚本**：为每个 framework target 添加 "Copy Privacy Manifest" 构建脚本阶段
3. **更新现有脚本**：如果脚本已存在，会更新为使用正确的路径

### 构建脚本功能

构建脚本会在 framework 构建完成后执行，将 `PrivacyInfo.xcprivacy` 文件从 Pods 目录复制到 framework bundle 的根目录。

**脚本路径**：

- 源文件：`${PODS_ROOT}/<SDK_NAME>/PrivacyInfo.xcprivacy`
- 目标位置：`${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/PrivacyInfo.xcprivacy`

## 验证步骤

### 1. 验证文件存在

```bash
# 检查所有 6 个 SDK 的隐私清单文件
ls -la Pods/{AFNetworking,FMDB,MBProgressHUD,SDWebImage,Starscream,Toast}/PrivacyInfo.xcprivacy
```

### 2. 验证构建脚本

```bash
# 检查构建脚本是否已添加（应该找到 6 个）
grep -c "Copy Privacy Manifest" Pods/Pods.xcodeproj/project.pbxproj
```

### 3. 验证构建脚本路径

```bash
# 检查脚本是否使用正确的路径变量（应该使用 PODS_ROOT，而不是 PODS_TARGET_SRCROOT）
grep "PODS_ROOT.*PrivacyInfo" Pods/Pods.xcodeproj/project.pbxproj
```

### 4. 构建后验证

构建项目后，检查 framework bundle 中是否包含隐私清单文件：

```bash
# 检查构建产物
find ~/Library/Developer/Xcode/DerivedData -name "AFNetworking.framework" -exec ls -la {}/PrivacyInfo.xcprivacy \;
find ~/Library/Developer/Xcode/DerivedData -name "FMDB.framework" -exec ls -la {}/PrivacyInfo.xcprivacy \;
find ~/Library/Developer/Xcode/DerivedData -name "MBProgressHUD.framework" -exec ls -la {}/PrivacyInfo.xcprivacy \;
find ~/Library/Developer/Xcode/DerivedData -name "SDWebImage.framework" -exec ls -la {}/PrivacyInfo.xcprivacy \;
find ~/Library/Developer/Xcode/DerivedData -name "Starscream.framework" -exec ls -la {}/PrivacyInfo.xcprivacy \;
find ~/Library/Developer/Xcode/DerivedData -name "Toast.framework" -exec ls -la {}/PrivacyInfo.xcprivacy \;
```

### 5. 归档验证

在归档应用后，验证归档文件中的 framework 是否包含隐私清单文件：

1. 在 Xcode Organizer 中，右键点击归档文件 -> "Show in Finder"
2. 检查 `.xcarchive/Products/Frameworks/` 目录
3. 验证每个 framework bundle 根目录是否包含 `PrivacyInfo.xcprivacy`

## 构建日志检查

构建时，应该看到以下调试输出：

```
🔍 Copying PrivacyInfo.xcprivacy for AFNetworking
   Source: ${PODS_ROOT}/AFNetworking/PrivacyInfo.xcprivacy
   Destination: ${BUILT_PRODUCTS_DIR}/AFNetworking.framework
✅ Successfully copied PrivacyInfo.xcprivacy to AFNetworking.framework
```

（类似输出会出现在所有 6 个 SDK 的构建过程中）

## 常见问题排查

### 问题 1：文件没有被复制到 framework bundle

**可能原因**：

- 构建脚本路径不正确
- 构建脚本执行时机不对
- 文件路径变量未正确解析

**解决方法**：

1. 检查构建日志中的调试输出
2. 确认脚本使用 `${PODS_ROOT}` 而不是 `${PODS_TARGET_SRCROOT}`
3. 确认脚本在 framework 构建完成后执行

### 问题 2：构建脚本未执行

**可能原因**：

- 脚本被添加到错误的构建阶段
- 脚本执行条件不满足

**解决方法**：

1. 在 Xcode 中检查 target 的 Build Phases
2. 确认 "Copy Privacy Manifest" 脚本在 Resources 阶段之后
3. 检查脚本的 "Run script only when installing" 选项是否未选中

### 问题 3：路径变量未解析

**可能原因**：

- 使用了错误的路径变量
- 路径变量在构建时不可用

**解决方法**：

1. 使用 `${PODS_ROOT}` 而不是 `${PODS_TARGET_SRCROOT}`
2. 确保路径变量在构建时可用

## 提交前检查清单

在提交到 App Store Connect 之前，请确认：

- [ ] 所有 6 个 SDK 的 PrivacyInfo.xcprivacy 文件都已创建
- [ ] 构建脚本已添加到所有 6 个 framework target
- [ ] 构建脚本使用正确的路径变量（`${PODS_ROOT}`）
- [ ] 构建日志显示文件被成功复制
- [ ] 构建产物中的 framework bundle 包含 PrivacyInfo.xcprivacy
- [ ] 归档文件中的 framework bundle 包含 PrivacyInfo.xcprivacy
- [ ] 所有隐私清单文件格式正确（有效的 plist 格式）
- [ ] 隐私清单文件包含所有必需字段

## 后续维护

### 添加新的第三方 SDK

如果将来添加了新的第三方 SDK，需要：

1. 检查该 SDK 是否在 Apple 的常用第三方 SDK 列表中
2. 如果是，在 `Podfile` 的 `sdk_names` 数组中添加 SDK 名称
3. 运行 `pod install` 以自动创建和配置隐私清单文件

### 更新 SDK 版本

更新 SDK 版本时：

1. 运行 `pod install` 确保隐私清单文件仍然存在
2. 验证构建脚本仍然正确配置
3. 重新构建并验证 framework bundle 包含隐私清单文件

## 参考资源

- [Apple 第三方 SDK 要求](https://developer.apple.com/support/third-party-SDK-requirements)
- [隐私清单文件格式](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [ITMS-91061 错误说明](https://developer.apple.com/documentation/technotes/tn3151)
