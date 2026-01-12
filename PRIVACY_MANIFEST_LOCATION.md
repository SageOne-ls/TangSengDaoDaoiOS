# PrivacyInfo.xcprivacy 文件位置说明

## Framework 结构类型

根据 framework 的类型和构建方式，`PrivacyInfo.xcprivacy` 文件可能位于两个不同的位置：

### 1. iOS Framework（扁平结构）

```
Framework.framework/
├── Framework (可执行文件)
├── PrivacyInfo.xcprivacy ✅ (根目录)
├── Headers/
└── Resources/ (可选)
```

**位置**: `Framework.framework/PrivacyInfo.xcprivacy`

### 2. macOS Framework 或某些特殊结构

```
Framework.framework/
├── Contents/
│   ├── Resources/
│   │   └── PrivacyInfo.xcprivacy ✅ (Contents/Resources/)
│   └── MacOS/
│       └── Framework (可执行文件)
└── Headers/
```

**位置**: `Framework.framework/Contents/Resources/PrivacyInfo.xcprivacy`

## 当前实现

我们的构建脚本已经更新，**自动支持两种结构**：

1. **优先检查** `Contents/Resources` 目录（macOS 风格）
2. **如果不存在**，则复制到 framework 根目录（iOS 风格）

### 构建脚本逻辑

```bash
# 检查是否存在 Contents/Resources 目录
if [ -d "$FRAMEWORK_DIR/Contents/Resources" ]; then
    # macOS 风格：复制到 Contents/Resources/
    DEST_PATH="$FRAMEWORK_DIR/Contents/Resources/PrivacyInfo.xcprivacy"
else
    # iOS 风格：复制到 framework 根目录
    DEST_PATH="$FRAMEWORK_DIR/PrivacyInfo.xcprivacy"
fi
```

## 检查方法

### 使用检查脚本

检查脚本已更新，可以自动检测两种位置：

```bash
./check_privacy_manifests.sh build
./check_privacy_manifests.sh ipa YourApp.ipa
```

脚本会显示文件的实际位置（framework root 或 Contents/Resources）。

### 手动检查

#### 检查 iOS 风格（根目录）

```bash
ls -la Framework.framework/PrivacyInfo.xcprivacy
```

#### 检查 macOS 风格（Contents/Resources）

```bash
ls -la Framework.framework/Contents/Resources/PrivacyInfo.xcprivacy
```

#### 同时检查两种位置

```bash
# 检查根目录
if [ -f "Framework.framework/PrivacyInfo.xcprivacy" ]; then
    echo "✅ 找到在根目录"
fi

# 检查 Contents/Resources
if [ -f "Framework.framework/Contents/Resources/PrivacyInfo.xcprivacy" ]; then
    echo "✅ 找到在 Contents/Resources"
fi
```

## Apple 官方要求

根据 Apple 的文档，`PrivacyInfo.xcprivacy` 应该位于：

> **Framework bundle 的根目录**（与 framework 可执行文件同级）

但是，对于使用 `Contents/Resources` 结构的 framework，文件应该放在 `Contents/Resources` 目录下。

## 验证清单

在提交到 App Store 之前，确保：

- [ ] 文件存在于 framework bundle 中（根目录或 Contents/Resources）
- [ ] 文件格式正确（有效的 plist XML）
- [ ] 文件大小不为 0
- [ ] 使用检查脚本验证所有 framework

## 常见问题

### Q: 如何确定我的 framework 使用哪种结构？

**A:** 检查 framework 目录结构：
```bash
ls -la Framework.framework/
```

- 如果看到 `Contents/` 目录 → macOS 风格 → 使用 `Contents/Resources/`
- 如果直接看到可执行文件 → iOS 风格 → 使用根目录

### Q: 两种位置都可以吗？

**A:** 是的，我们的构建脚本会自动检测并使用正确的位置。Apple 会根据 framework 的实际结构来查找文件。

### Q: 如果两种位置都有文件会怎样？

**A:** 我们的脚本只会创建一个文件，优先使用 `Contents/Resources`（如果存在）。Apple 的检查工具会查找两个位置，找到任何一个即可。

## 更新日志

- **2024-12-26**: 更新构建脚本，支持两种 framework 结构
- **2024-12-26**: 更新检查脚本，可以检测两种位置

