# Deep Research Workflow

**Load this reference when:** conducting multi-source research, synthesizing findings.

## 6-Step Research Process

### Step 1: Understand Goal

Ask 1-2 quick clarifying questions:
- "What's your goal — learning, making a decision, or writing something?"
- "Any specific angle or depth you want?"

If user says "just research it" — proceed with reasonable defaults.

### Step 2: Plan Research

Break topic into 3-5 sub-questions:

```
Topic: "Impact of AI on healthcare"
- What are the main AI applications today?
- What clinical outcomes have been measured?
- What are the regulatory challenges?
- What companies are leading?
- What's the market size?
```

### Step 3: Execute Search

For EACH sub-question, search with 2-3 variations:
```
firecrawl_search(query: "keywords", limit: 8)
web_search_exa(query: "keywords", numResults: 8)
web_search_advanced_exa(query: "keywords", numResults: 5, startPublishedDate: "2025-01-01")
```

### Step 4: Deep-Read Sources

Fetch 3-5 promising URLs in full:
```
firecrawl_scrape(url: "url")
crawling_exa(url: "url", tokensNum: 5000)
```

### Step 5: Synthesize Report

Structure the report with inline citations:
```markdown
## Key Point
Supporting detail ([Source Name](url))

## Sources
[Title](url) — one-line summary
```

### Step 6: Deliver

- Short topics: Post in chat
- Long reports: Post summary + save to file