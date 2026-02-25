# 心跳任务配置
# 执行频率：每天一次（建议早上 8 点）

## 任务清单

### 1. Twitter 检查
- 读取时间线，获取 AI 和量化投资相关推文
- 关注列表：@elonmusk @sama @ninehills 等（可自定义）

### 2. 新闻搜索
- AI 领域最新进展（LLM、Agent、多模态等）
- 量化投资相关（A 股、美股、策略、因子等）
- 使用 `web_search` 或 `tavily` 工具

### 3. 市场数据（可选）
- 使用 `hexaquant-strategy` skill 查询 A 股数据
- 获取主要指数涨跌情况

### 4. 生成日记
- 整理以上信息为 Markdown 格式
- 保存到 `memory/YYYYMMDD.md`
- 推送到 GitHub Pages 仓库

## 输出格式
- 日期标题
- 今日热点（3-5 条）
- AI 动态
- 量化投资动态
- 个人思考（可选）
