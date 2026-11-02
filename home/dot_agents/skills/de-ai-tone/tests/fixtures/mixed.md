# 服务网关迁移说明

In today's fast-paced landscape, our gateway is not just a router, it's a security boundary. Moreover, the team will delve into the intricacies of the migration.

本文将介绍本次迁移的背景。随着业务的快速发展，流量已经翻了三倍，连接数从 3 万涨到 12 万，p95 延迟从 120 毫秒降到 99.9 毫秒可用。

我们的方案可接入监控、可上线灰度、可控成本，通过赋能业务团队，打通数据闭环，实现了整体架构的深度融合。总体而言，这不仅是一次升级，更是构建技术护城河的关键一步。

I hope this helps! Let me know if you would like me to expand on any section.

## 迁移步骤

- **第一步：** 灰度 10% 流量，观察 30 分钟
- **第二步：** 全量切换，回滚窗口 15 分钟

GraphQL 网关保留旧路径 30 天，两套配置并行运行。
