# clawbot-diary 生成脚本 v2.0

使用 Twitter (x-twitter/twclaw) + Tavily AI 搜索自动生成每日投资日记。

## 功能特性

- 🐦 **Twitter 实时搜索**: 获取 AI/AGI、量化投资领域的最新推文
- 🔍 **Tavily AI 深度搜索**: 执行多个主题的深度新闻搜索
- 📝 **自动格式化**: 生成结构化的 Markdown 日记
- 🔄 **每日更新**: 自动创建按日期命名的日记文件

## 前置条件

1. **Twitter API**: 设置 `TWITTER_BEARER_TOKEN` 环境变量
   ```bash
   export TWITTER_BEARER_TOKEN="your_bearer_token"
   ```

2. **twclaw 工具**: 已安装 Twitter CLI 工具
   ```bash
   npm install -g twclaw
   ```

3. **Node.js**: 用于执行 Tavily API 调用

## 使用方法

### 生成今日日记

```bash
cd /home/bingo/.picoclaw/workspace/clawbot-diary
./generate-diary.sh
```

### 手动查看生成的日记

```bash
cat /home/bingo/.picoclaw/workspace/clawbot-diary/202602/$(date +%Y%m%d).md
```

## 输出示例

日记文件包含以下部分：

1. **Twitter 观察 & 思考**
   - AI 领域热点推文
   - 量化投资相关推文
   - Twitter 热门话题

2. **Tavily AI 深度搜索**
   - AI/AGI 技术突破
   - 量化交易策略
   - 市场分析

3. **个人思考区** (手动填写)

4. **TODO 列表** (自动创建)

## 自定义搜索主题

编辑 `generate-diary.sh` 中的搜索关键词：

```bash
# AI 领域搜索
TWITTER_AI=$(twclaw search "AI OR AGI OR artificial intelligence" -n 5 --plain)

# 量化投资搜索
TWITTER_QUANT=$(twclaw search "quantitative trading OR quant strategy" -n 5 --plain)
```

## 自动化

可以通过 cron 定时执行：

```bash
# 每天 23:30 生成日记
30 23 * * * /home/bingo/.picoclaw/workspace/clawbot-diary/generate-diary.sh
```

## 故障排除

### Twitter API 错误
- 检查 `TWITTER_BEARER_TOKEN` 是否设置
- 运行 `twclaw auth-check` 验证凭证
- 注意 Twitter API 速率限制

### Tavily 搜索失败
- 检查网络连接
- 验证 API key 是否有效
- 查看 Node.js 版本兼容性

## 文件结构

```
clawbot-diary/
├── generate-diary.sh      # 主生成脚本
├── README.md              # 本文件
├── sync-diary.sh          # 同步脚本 (可选)
└── 202602/                # 按月组织的日记
    ├── 20260225.md
    └── ...
```

## 版本历史

- **v2.0**: 整合 Twitter (twclaw) + Tavily AI 搜索
- **v1.1**: 基础模板 + 手动数据填充
- **v1.0**: 初始版本

---

**作者**: OpenClaw  
**许可**: MIT
