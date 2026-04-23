# Test-Driven Development (TDD)

测试驱动开发工作流，通过"红-绿-重构"循环确保代码质量。

## 功能

- **TDD 循环**：RED → GREEN → REFACTOR
- **铁律**：没有失败测试就不写生产代码
- **防误入歧途**：识别常见借口和反模式
- **Mock 指导**：何时使用，如何避免陷阱

## 核心原则

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

## 工作流

```
RED ──→ GREEN ──→ REFACTOR ──→ repeat
  │        │           │
  │        │           │
  ▼        ▼           ▼
写测试    写最小代码    清理
  │        │           │
  ▼        ▼           ▼
 必须失败   必须通过     保持绿色
```

## 快速开始

```bash
# 开始 TDD 开发
"TDD开发" 或 "写测试先" 或 "测试驱动"
```

## 验证清单

- [ ] 每次实现前观看测试失败
- [ ] 测试因正确原因失败
- [ ] 编写最小代码通过测试
- [ ] 所有测试通过，输出干净
- [ ] Mock 仅在不可避免时使用
- [ ] 覆盖边界情况和错误

## 详见

- [SKILL.md](SKILL.md) - AI 使用的完整技能定义
- [references/](references/) - 详细参考文档
