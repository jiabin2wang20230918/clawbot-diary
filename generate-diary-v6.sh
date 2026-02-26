#!/bin/bash
# clawbot-diary 生成脚本 v6.0
# AI 自主搜索 + 生成版：让 AI 自己决定搜索内容并生成日记

set -e

# ========== 配置 ==========
WORKSPACE="/home/bingo/.picoclaw/workspace"
DIARY_DIR="$WORKSPACE/clawbot-diary"
MONTH_DIR=$(date +%Y%m)
TODAY=$(date +%Y%m%d)
OUTPUT_FILE="$DIARY_DIR/$MONTH_DIR/$TODAY.md"
TEMP_DIR="/tmp/clawbot-diary-v6-$$"

# AI 模型配置（使用 main model）
# 支持: claude, openai, 或自定义
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
OPENAI_API_KEY="${OPENAI_API_KEY:-}"
MODEL="${MODEL:-claude-sonnet-4-20250514}"

# 确保目录存在
mkdir -p "$DIARY_DIR/$MONTH_DIR"
mkdir -p "$TEMP_DIR"

# 清理函数
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# ========== 工具函数 ==========

# 调用 Claude API
call_claude() {
    local prompt="$1"
    local system_prompt="${2:-}"
    
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "❌ ANTHROPIC_API_KEY 未配置"
        return 1
    fi
    
    curl -s -X POST "https://api.anthropic.com/v1/messages" \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"$MODEL\",
            \"max_tokens\": 8000,
            \"system\": \"$system_prompt\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]
        }" | jq -r '.content[0].text // .error.message' 2>/dev/null
}

# 调用 OpenAI API
call_openai() {
    local prompt="$1"
    local system_prompt="${2:-}"
    
    if [ -z "$OPENAI_API_KEY" ]; then
        echo "❌ OPENAI_API_KEY 未配置"
        return 1
    fi
    
    curl -s -X POST "https://api.openai.com/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"gpt-4o\",
            \"max_tokens\": 8000,
            \"temperature\": 0.7,
            \"system\": \"$system_prompt\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]
        }" | jq -r '.choices[0].message.content // .error.message' 2>/dev/null
}

# 通用 AI 调用（自动选择）
call_ai() {
    local prompt="$1"
    local system_prompt="$2"
    
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        call_claude "$prompt" "$system_prompt"
    elif [ -n "$OPENAI_API_KEY" ]; then
        call_openai "$prompt" "$system_prompt"
    else
        echo "❌ 未配置 AI API Key"
        return 1
    fi
}

# 执行搜索
do_search() {
    local query="$1"
    local count="${2:-8}"
    
    "$WORKSPACE/tavily_search.sh" "$query" $count 2>/dev/null || echo "搜索失败: $query"
}

# ========== 日期信息 ==========
get_date_info() {
    YEAR=$(date +%Y)
    MONTH=$(date +%m)
    DAY=$(date +%d)
    WEEKDAY=$(date -u -d "$YEAR-$MONTH-$DAY" +%A)
    case $WEEKDAY in
        Monday) WEEKDAY_CN="星期一" ;;
        Tuesday) WEEKDAY_CN="星期二" ;;
        Wednesday) WEEKDAY_CN="星期三" ;;
        Thursday) WEEKDAY_CN="星期四" ;;
        Friday) WEEKDAY_CN="星期五" ;;
        Saturday) WEEKDAY_CN="星期六" ;;
        Sunday) WEEKDAY_CN="星期日" ;;
    esac
    
    DAY_OF_YEAR=$(date -u -d "$YEAR-$MONTH-$DAY" +%j)
    DAY_OF_YEAR=$((10#$DAY_OF_YEAR))
    
    # 农历（简化）
    LUNAR_INFO="$MONTH 月 $DAY 日"
    
    # 节气
    case $MONTH in
        02) SOLAR_TERM="雨水" ;;
        03) SOLAR_TERM="春分" ;;
        04) SOLAR_TERM="清明" ;;
        05) SOLAR_TERM="谷雨" ;;
        06) SOLAR_TERM="夏至" ;;
        07) SOLAR_TERM="小暑" ;;
        08) SOLAR_TERM="立秋" ;;
        09) SOLAR_TERM="白露" ;;
        10) SOLAR_TERM="寒露" ;;
        11) SOLAR_TERM="立冬" ;;
        12) SOLAR_TERM="大雪" ;;
        01) SOLAR_TERM="小寒" ;;
    esac
}

# ========== 主流程 ==========

echo "🚀 开始生成 $(date +%Y-%m-%d) 日记 (v6.0 AI 自主搜索版)..."
echo ""

# 检查 AI 可用性
if ! call_ai "test" "你是一个测试助手，请回复 'OK'" > /dev/null 2>&1; then
    echo "❌ AI API 不可用，请检查 API Key 配置"
    exit 1
fi
echo "✓ AI 模型已就绪"
echo ""

# 获取日期信息
get_date_info

# ========== 第一步：让 AI 决定搜索策略 ==========
echo "🧠 AI 正在思考今天的搜索策略..."

SEARCH_STRATEGY_PROMPT="今天是 $YEAR 年 $MONTH 月 $DAY 日，$WEEKDAY_CN。

请为以下5个搜索维度各生成一个精确的搜索查询（英文）：

1. AI/AGI 领域最新突破和技术进展
2. 量化交易策略和 A 股市场分析
3. 全球股市和科技股动态
4. 中国 AI 科技发展（DeepSeek、字节等）
5. AI Agent 和自动化商务应用

要求：
- 每个查询要能搜到最新、最相关的新闻
- 使用英文关键词，混合使用 news 和 general 搜索
- 输出格式：每行一个查询，共5行，不要其他内容"

SEARCH_QUERIES=$(call_ai "$SEARCH_STRATEGY_PROMPT" "你是一个专业的AI新闻搜索策略专家。请根据日期和热点生成最佳搜索查询。")

if [ -z "$SEARCH_QUERIES" ]; then
    echo "⚠ AI 未能生成搜索策略，使用默认查询"
    SEARCH_QUERIES="AI AGI breakthrough February 2026
quantitative trading China A-stock alpha strategy 2026
stock market tech NVIDIA AI February 2026
China AI DeepSeek ByteDance technology 2026
AI Agent autonomous payment commerce 2026"
fi

echo "✓ 搜索策略已确定"
echo "---"
echo "$SEARCH_QUERIES"
echo "---"
echo ""

# ========== 第二步：执行搜索 ==========
echo "🔍 执行多维度搜索..."

# 将查询解析为数组
mapfile -t QUERY_ARRAY <<< "$SEARCH_QUERIES"

# 定义搜索维度
DIMENSIONS=("ai_tech" "quant" "market" "china_ai" "agent")

for i in "${!DIMENSIONS[@]}"; do
    dim="${DIMENSIONS[$i]}"
    query="${QUERY_ARRAY[$i]}"
    
    if [ -n "$query" ]; then
        count=8
        [[ "$dim" == "agent" ]] && count=5
        
        echo "   - $dim: ${query:0:50}..."
        do_search "$query" $count > "$TEMP_DIR/search_$dim.txt"
    fi
done

echo "✓ 搜索完成"
echo ""

# ========== 第三步：整理搜索结果 ==========
echo "📋 整理搜索结果..."

{
    echo "=== AI 技术进展 (AI Tech) ==="
    cat "$TEMP_DIR/search_ai_tech.txt"
    echo ""
    echo "=== 量化投资 (Quantitative) ==="
    cat "$TEMP_DIR/search_quant.txt"
    echo ""
    echo "=== 市场动态 (Market) ==="
    cat "$TEMP_DIR/search_market.txt"
    echo ""
    echo "=== 中国 AI (China AI) ==="
    cat "$TEMP_DIR/search_china_ai.txt"
    echo ""
    echo "=== Agent 商务 (Agent) ==="
    cat "$TEMP_DIR/search_agent.txt"
} > "$TEMP_DIR/all_search_results.txt"

SEARCH_RESULTS=$(cat "$TEMP_DIR/all_search_results.txt")

echo "✓ 搜索结果已整理 ($(echo "$SEARCH_RESULTS" | wc -l) 行)"
echo ""

# ========== 第四步：让 AI 生成日记 ==========
echo "🤖 AI 正在生成深度日记分析..."

DIARY_SYSTEM_PROMPT="你是一位专业的 AI 和量化投资领域分析师，擅长从新闻中提取关键洞察并进行深度分析。

你的任务是生成一篇高质量的每日日记，包含：

1. 【日期标题】格式：# YYYY 年 MM 月 DD 日 星期X
2. 【今日热点】用 3-4 句话总结今天 AI 领域最重要的新闻和影响
3. 【市场影响】分析这些动态对投资市场的潜在影响
4. 【独立思考】给出你对这个趋势的独特见解（至少 2 点）
5. 【量化观察】关于 A 股量化策略的思考
6. 【一句话总结】用一句话概括今日核心洞察

要求：
- 使用中文输出
- 简洁、有深度、有独立思考
- 不要使用 emoji
- 直接输出，不要有其他解释"

DIARY_USER_PROMPT="今天是 $YEAR 年 $MONTH 月 $DAY 日，$WEEKDAY_CN，农历$LUNAR_INFO，$SOLAR_TERM节气，第 $DAY_OF_YEAR 天。

请根据以下搜索结果生成今日日记：

$SEARCH_RESULTS"

DIARY_OUTPUT=$(call_ai "$DIARY_USER_PROMPT" "$DIARY_SYSTEM_PROMPT")

if [ -z "$DIARY_OUTPUT" ]; then
    echo "❌ AI 生成日记失败"
    exit 1
fi

echo "✓ AI 日记生成完成"
echo ""

# ========== 第五步：保存日记 ==========
echo "📝 保存日记..."

# 写入日记文件
cat > "$OUTPUT_FILE" << EOF
$DIARY_OUTPUT

---

*生成于 $(date +"%Y-%m-%d %H:%M") | OpenClaw 日记 v6.0 (AI 自主搜索版)*
*注：本日记基于 Tavily AI 实时搜索 + AI 深度分析生成*
*数据来源：Tavily AI Search API | AI Model: $MODEL*
EOF

# 保存原始数据
cp "$TEMP_DIR"/*.txt "$DIARY_DIR/$MONTH_DIR/" 2>/dev/null || true

echo "✓ 日记保存完成"
echo ""
echo "📄 输出文件：$OUTPUT_FILE"
echo "💾 原始搜索数据：$DIARY_DIR/$MONTH_DIR/"
echo ""
echo "✨ 完成！"