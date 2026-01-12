#!/bin/bash
# 更新 Git 用户邮箱（括号里的内容）
# 使用方法: ./update_git_email.sh <新邮箱地址>

if [ -z "$1" ]; then
    echo "❌ 错误: 请提供新的邮箱地址"
    echo "使用方法: ./update_git_email.sh <新邮箱地址>"
    echo "示例: ./update_git_email.sh yourname@example.com"
    exit 1
fi

NEW_EMAIL="$1"
CURRENT_EMAIL=$(git config user.email)
CURRENT_NAME=$(git config user.name)

echo "📧 更新 Git 邮箱配置..."
echo "当前配置: $CURRENT_NAME <$CURRENT_EMAIL>"
echo "新邮箱: $NEW_EMAIL"
echo ""

# 更新全局配置（推荐，影响所有仓库）
read -p "是否更新全局配置？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git config --global user.email "$NEW_EMAIL"
    echo "✅ 全局邮箱已更新为: $NEW_EMAIL"
else
    # 只更新当前仓库
    git config user.email "$NEW_EMAIL"
    echo "✅ 当前仓库邮箱已更新为: $NEW_EMAIL"
fi

echo ""
echo "📝 验证配置:"
echo "用户名: $(git config user.name)"
echo "邮箱: $(git config user.email)"
echo ""
echo "💡 提示:"
echo "   - 新的提交将使用新的邮箱地址"
echo "   - 历史提交记录不会自动更改"
echo "   - 如需修改历史提交，请使用 git filter-branch 或 git filter-repo"


