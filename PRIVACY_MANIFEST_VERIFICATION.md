# 隐私清单文件验证和合规性检查

## Apple 第三方 SDK 要求总结

根据 [Apple 第三方 SDK 要求](https://developer.apple.com/support/third-party-SDK-requirements)：

1. **常用第三方 SDK 必须包含隐私清单文件**：如果应用包含 Apple 文档中列出的常用第三方 SDK，这些 SDK 必须包含 `PrivacyInfo.xcprivacy` 文件。

2. **文件位置要求**：`PrivacyInfo.xcprivacy` 必须位于 framework bundle 的根目录（与 framework 可执行文件同级）。

3. **文件格式要求**：必须是有效的 plist 格式，包含以下必需字段：
   - `NSPrivacyAccessedAPITypes` - 访问的隐私 API 类型
   - `NSPrivacyCollectedDataTypes` - 收集的数据类型
   - `NSPrivacyTrackingDomains` - 跟踪域名
   - `NSPrivacyTracking` - 是否进行跟踪

## 已处理的 SDK 列表

以下 6 个 SDK 已创建并配置隐私清单文件：

1. ✅ **AFNetworking** - `Pods/AFNetworking/PrivacyInfo.xcprivacy`
2. ✅ **FMDB** - `Pods/FMDB/PrivacyInfo.xcprivacy`
3. ✅ **MBProgressHUD** - `Pods/MBProgressHUD/PrivacyInfo.xcprivacy`
4. ✅ **SDWebImage** - `Pods/SDWebImage/PrivacyInfo.xcprivacy`
5. ✅ **Starscream** - `Pods/Starscream/PrivacyInfo.xcprivacy`
6. ✅ **Toast** - `Pods/Toast/PrivacyInfo.xcprivacy`

## 项目配置检查

### 1. Podfile 配置 ✅

- ✅ 在 `post_install` hook 中自动创建隐私清单文件
- ✅ 为每个 framework target 添加 "Copy Privacy Manifest" 构建脚本
- ✅ 构建脚本会在 framework 构建完成后执行
- ✅ 脚本会尝试多个可能的框架路径位置

### 2. 构建脚本路径

**源文件路径**：
- `${PODS_TARGET_SRCROOT}/PrivacyInfo.xcprivacy` 
- 等同于：`${PODS_ROOT}/<SDK_NAME>/PrivacyInfo.xcprivacy`

**目标路径**（按优先级尝试）：
1. `${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}/${PRODUCT_NAME}.framework`
2. `${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework`
3. `${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/${PRODUCT_NAME}.framework`

### 3. 隐私清单文件内容

所有文件都声明：
- ❌ 不访问任何隐私 API
- ❌ 不收集任何数据
- ❌ 不进行跟踪
- ❌ 不跟踪用户

## 验证步骤

### 步骤 1：验证文件存在

```bash
# 检查所有 6 个 SDK 的隐私清单文件
ls -la Pods/{AFNetworking,FMDB,MBProgressHUD,SDWebImage,Starscream,Toast}/PrivacyInfo.xcprivacy
```

**预期结果**：所有 6 个文件都应该存在。

### 步骤 2：验证构建脚本

```bash
# 检查构建脚本是否已添加（应该找到 6 个）
grep -c "Copy Privacy Manifest" Pods/Pods.xcodeproj/project.pbxproj
```

**预期结果**：应该找到 15 个匹配（每个 SDK 的脚本定义和引用）。

### 步骤 3：清理并重新构建

在 Xcode 中：
1. **Product -> Clean Build Folder** (Shift+Cmd+K)
2. **重新构建项目** (Cmd+B)
3. **检查构建日志**，应该看到：
   ```
   🔍 Copying PrivacyInfo.xcprivacy for AFNetworking
      Source: ${PODS_ROOT}/AFNetworking/PrivacyInfo.xcprivacy
      Destination: ...
   ✅ Successfully copied PrivacyInfo.xcprivacy to AFNetworking.framework
   ```

### 步骤 4：验证构建产物

构建完成后，检查 framework bundle：

```bash
# 检查所有 6 个 SDK 的 framework
for sdk in AFNetworking FMDB MBProgressHUD SDWebImage Starscream Toast; do
    echo "=== Checking $sdk ==="
    find ~/Library/Developer/Xcode/DerivedData -name "${sdk}.framework" -type d -exec ls -la {}/PrivacyInfo.xcprivacy \; 2>&1 | head -1
done
```

**预期结果**：所有 6 个 framework 都应该包含 `PrivacyInfo.xcprivacy` 文件。

### 步骤 5：归档验证

1. **在 Xcode 中归档应用** (Product -> Archive)
2. **在 Organizer 中**，右键点击归档文件 -> "Show in Finder"
3. **检查归档文件**：
   ```bash
   # 检查归档文件中的 framework
   find ~/Library/Developer/Xcode/Archives -name "*.xcarchive" -type d -mtime -1 | head -1 | xargs -I {} find {} -name "*.framework" -type d | while read fw; do
       echo "Checking $fw"
       ls -la "$fw/PrivacyInfo.xcprivacy" 2>&1
   done
   ```

**预期结果**：所有 6 个 framework 都应该包含 `PrivacyInfo.xcprivacy` 文件。

## 常见问题排查

### 问题 1：构建脚本未执行

**症状**：构建日志中没有看到 "🔍 Copying PrivacyInfo.xcprivacy" 消息。

**可能原因**：
- 脚本被添加到错误的构建阶段
- 脚本执行条件不满足

**解决方法**：
1. 在 Xcode 中打开 `Pods.xcodeproj`
2. 选择对应的 framework target（如 AFNetworking）
3. 检查 Build Phases，确认 "Copy Privacy Manifest" 脚本存在
4. 确认脚本在 Resources 阶段之后
5. 确认 "Run script only when installing" 选项未选中

### 问题 2：文件路径错误

**症状**：构建日志显示 "❌ Error: PrivacyInfo.xcprivacy not found"。

**可能原因**：
- `${PODS_TARGET_SRCROOT}` 变量未正确解析
- 文件不在预期位置

**解决方法**：
1. 检查构建日志中的实际路径
2. 确认文件存在于 `Pods/<SDK_NAME>/PrivacyInfo.xcprivacy`
3. 如果路径不正确，手动检查 `.xcconfig` 文件中的路径变量

### 问题 3：Framework 目录未找到

**症状**：构建日志显示 "❌ Error: Framework directory not found"。

**可能原因**：
- Framework 输出路径与脚本预期不符
- Framework 尚未构建完成

**解决方法**：
1. 检查构建日志中的实际框架路径
2. 确认脚本在 framework 构建完成后执行
3. 脚本已更新为尝试多个可能的路径位置

### 问题 4：文件被复制但不在根目录

**症状**：文件存在于 framework bundle 中，但不在根目录。

**可能原因**：
- 文件被复制到错误的子目录
- Resources 构建阶段将文件复制到了 Resources 子目录

**解决方法**：
1. 确认使用构建脚本而不是 Resources 构建阶段
2. 确认脚本将文件复制到 framework bundle 根目录
3. 检查 framework bundle 结构：
   ```bash
   ls -la <framework_path>/
   # 应该看到：PrivacyInfo.xcprivacy 与可执行文件同级
   ```

## 提交前最终检查清单

在提交到 App Store Connect 之前，请确认：

- [ ] ✅ 所有 6 个 SDK 的 PrivacyInfo.xcprivacy 文件都已创建
- [ ] ✅ 构建脚本已添加到所有 6 个 framework target
- [ ] ✅ 构建日志显示所有文件被成功复制
- [ ] ✅ 构建产物中的 framework bundle 包含 PrivacyInfo.xcprivacy（在根目录）
- [ ] ✅ 归档文件中的 framework bundle 包含 PrivacyInfo.xcprivacy（在根目录）
- [ ] ✅ 所有隐私清单文件格式正确（有效的 plist 格式）
- [ ] ✅ 所有隐私清单文件包含所有必需字段
- [ ] ✅ 隐私清单文件内容准确反映了 SDK 的实际行为

## 后续维护

### 添加新的第三方 SDK

如果将来添加了新的第三方 SDK：

1. 检查该 SDK 是否在 [Apple 的常用第三方 SDK 列表](https://developer.apple.com/support/third-party-SDK-requirements)中
2. 如果是，在 `Podfile` 的 `sdk_names` 数组中添加 SDK 名称：
   ```ruby
   sdk_names = ['AFNetworking', 'FMDB', 'MBProgressHUD', 'SDWebImage', 'Starscream', 'Toast', 'NewSDK']
   ```
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

