#!/bin/bash
# 快速迁移 Git 仓库到新的 GitHub 地址
# 使用方法: ./migrate_to_new_repo.sh <你的GitHub用户名>/<新仓库名>

if [ -z "$1" ]; then
    echo "❌ 错误: 请提供新的 GitHub 仓库地址"
    echo "使用方法: ./migrate_to_new_repo.sh <你的GitHub用户名>/<新仓库名>"
    echo "示例: ./migrate_to_new_repo.sh myusername/TangSengDaoDaoiOS"
    exit 1
fi

NEW_REPO_URL="https://github.com/$1.git"

echo "📦 开始迁移仓库..."
echo "当前远程仓库: $(git remote get-url origin)"
echo "新远程仓库: $NEW_REPO_URL"
echo ""

# 1. 更改远程仓库地址
echo "1️⃣  更改远程仓库地址..."
git remote set-url origin "$NEW_REPO_URL"
echo "✅ 远程地址已更新"

# 2. 获取所有远程分支和标签
echo ""
echo "2️⃣  获取所有远程分支和标签..."
git fetch origin

# 3. 推送所有分支
echo ""
echo "3️⃣  推送所有分支到新仓库..."
git push origin --all

# 4. 推送所有标签
echo ""
echo "4️⃣  推送所有标签到新仓库..."
git push origin --tags

echo ""
echo "✅ 迁移完成！"
echo "新仓库地址: $NEW_REPO_URL"
echo ""
echo "💡 提示:"
echo "   - 如果推送失败，请确保新仓库已创建且你有推送权限"
echo "   - 如果使用 SSH，可以将 URL 改为: git@github.com:$1.git"


