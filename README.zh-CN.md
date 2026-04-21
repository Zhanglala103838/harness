# Harness

> **Harness 不是 linter。Harness 是让你的代码库不再重复犯同一个架构错误的系统。**

`.harness/` 是一个可直接拖进你仓库的目录——把过去踩过的坑沉淀成 AI 和人都绕不过去的边界。

- **不是 lint 替代品**：ESLint / Prettier / `tsc` / `pylint` 管代码风格；harness 管这些工具看不见的东西——跨层泄漏、平行真相、配置和代码的漂移、元数据在错误的层被解释。
- **为 AI 时代代码库而生**：当 AI 生成大部分 diff 时，真正持久的杠杆是"它必须读过才能动手"的硬边界。Harness 把边界落成同步的三层：**spec → rules → checks**。
- **自我演进**：规则有生命周期——诞生、稳定、退役。Harness 会自检健康，死规则不会默默烂掉。

📖 English README: [README.md](./README.md)

---

## 你会得到什么

```
.harness/
├── README.md                    ← 团队 5 分钟上手说明
├── config.yaml                  ← rules ↔ checks 的机器可读映射
├── session-start.md             ← AI 会话开场必读仪式
├── evolve.md                    ← 自升级 / 自退役协议
├── violations-triage.md         ← 带到期日的豁免追踪
├── CHANGELOG.md                 ← 规则变更版本历史
├── rules/
│   ├── _TEMPLATE.md             ← 复制它来写新规则
│   └── <你的规则>.md             ← 一条硬边界 = 一份 markdown
└── checks/
    ├── _TEMPLATE.sh             ← 复制它来写新 check
    ├── check-harness-health.sh  ← harness 自检（开箱自带）
    └── <你的 check>.sh           ← grep/diff/size 执行脚本
```

## 三层结构

| 层 | 内容 | 谁在读 |
|---|---|---|
| **Spec**（在 `.harness/` 之外，项目的 `docs/` / `adr/`）| 长期方向——架构决策、ADR、事后复盘 | 人 + AI 做设计时 |
| **Rules**（`.harness/rules/`）| 边界本身——每条一份 markdown，含 Why + 判断方法 + 反例/正例 | 人 + AI 每次改代码时 |
| **Checks**（`.harness/checks/`）| 强制执行——grep/diff/count 的短 bash 脚本，阻断 PR | CI + commit 前的人 |

**关系**：Spec 决策 → 下沉到 Rule → 下沉到 Check。只留在 spec 的决策会被遗忘；没有 rule 的 check 是个谜；没有 check 的 rule 是个愿望。

## 为什么需要它

典型代码库里，三类失控反复发生：

1. **平行真相**：同一个字段 / 权限 / 配置存在 3 个地方，静默漂移
2. **边界侵蚀**：业务逻辑漏到表现层；元数据解释漏进 service
3. **配置驱动系统里的硬编码后门**："就这一次"硬写了一条本该在数据库的规则，然后永远留下

通用 linter 测不出这些——它们是你团队**已经付过学费**的项目专属模式。Harness 把它们沉淀一次，然后拒绝让它们再进来。

## 安装

```bash
# 选项 A：curl 一行搞定
curl -fsSL https://raw.githubusercontent.com/Zhanglala103838/harness/main/scripts/install.sh | bash

# 选项 B：clone + 拷贝
git clone https://github.com/Zhanglala103838/harness.git /tmp/harness
cp -r /tmp/harness/template/.harness ./.harness

# 选项 C：手动
# 下载 template/.harness/ 直接丢进你的仓库根目录
```

然后打开 `.harness/README.md` 把占位符改成你项目的信息。

## 快速开始（5 分钟）

1. **安装**（上面）
2. **编辑 `.harness/config.yaml`**——填 `project:` 和 `layers:`（你的架构分层）
3. **种下第一条 rule**——拷贝 `rules/_TEMPLATE.md` 到 `rules/<你的规则>.md`。**挑一个你已经踩过 ≥ 2 次的真实坑**
4. **种下第一条 check**——拷贝 `checks/_TEMPLATE.sh` 到 `checks/check-<你的规则>.sh`。让它 grep 违反模式
5. **接线**——`package.json` 加：`"harness:check": "bash -c 'for f in .harness/checks/check-*.sh; do bash \"$f\" || exit 1; done'"`
6. **跑一次**——`npm run harness:check`。绿 = 干净；红 = 有欠的债
7. **提交**——从现在起，每个 PR merge 前都必须通过这关

完整指南：[`docs/getting-started.md`](./docs/getting-started.md)

## AI 集成

Harness 和具体 AI 工具无关，能配合任何能在 session 开头读 markdown 的 agent。

**核心契约**：AI 动手写代码前必须声明 _"已读 .harness/session-start.md · 本次任务类型 = X · 生效规则 = R-a, R-b"_。没这句话的 PR 一律拒。

各家工具接线方式见 [`docs/ai-integration.md`](./docs/ai-integration.md)。

## 彩蛋模式（按需选用）

不是 harness 强制，但经常和它一起用：

- **[元规则（认知族）](./docs/meta-rules.md)**——MR-* 族规则，管"AI 怎么推理"（和 R-* 管"代码长什么样"并列）
- **[Hook 集成](./docs/hook-integration.md)**——SessionStart / PreToolUse hook 让 harness 上下文从"opt-in"变成"绕不过"
- **[二次 review 协议](./docs/external-review.md)**——双 AI 协作：主 AI 干活 · review AI 在固定触发点介入 · 冲突默认 reviewer 正确
- **[三阶段 code review 管线](./docs/review-pipeline.md)**——把 review 拆成 bug-finder / 安全-质量 / 重构三并行 pass，每 pass 信号更锐利
- **[Commit 规范](./docs/commit-convention.md)**——`<type>(<scope>): <subject>`，和 harness 的每项目 CHANGELOG 完美配合
- **[改第三方组件 bug 前必读 vendor 源码](./template/.harness/rules/example-read-vendor-source-before-patching.md)**——种子规则，专治"符合直觉但治标不治本"的 setTimeout 类修复
- **[同文件三振出局](./template/.harness/rules/example-three-strikes-same-file.md)**——同文件连续 3 轮不同诊断的 bugfix → 停手，做根因重分析，不再打补丁
- **[改模型 · 不要糊 UI](./template/.harness/rules/example-schema-before-ui-patch.md)**——元规则种子：数据模型缺字段时，去改模型而不是在 UI 里 `?? defaultValue`
- **[mock 测试过了 ≠ 真跑通](./template/.harness/rules/example-real-verification-over-mocks.md)**——元规则种子：DB / resolver / migration 类修复，"tests pass" 不构成完成证据
- **[展示字段前先问 3 问](./template/.harness/rules/example-ui-purpose-first.md)**——元规则种子：用户在这界面做什么？这字段提供什么？没它会怎样？答不出就别展示

## 哲学

完整版见 [`docs/evolution.md`](./docs/evolution.md)。一段话总结：

> 规则从失败重现中诞生，以人类可读的 markdown 写下来。如果违反模式可以 grep，它毕业成自动 check。如果失败模式消失（架构把根因解决了），规则退役。Harness 自己会检查这个生命周期没有停滞——没有被遗忘的豁免，没有死去的 check，没有无文档的规则。**harness 自身的漂移本身就是一个信号。**

## 这个项目**不是**什么

- ❌ 你 linter / 类型检查 / 测试套件的替代品
- ❌ 通用"最佳实践"规则手册（那种东西你只会无视）
- ❌ 框架绑定（就是 bash + markdown + YAML）
- ❌ pre-commit hook 套件（harness 不管你怎么跑——`husky` / `lefthook` / CI job 自己选）
- ❌ AI 越狱工具（人类一样能从中受益）

## 许可

MIT——见 [`LICENSE`](./LICENSE)

## 贡献

项目早期。如果你采用了，开一个 issue 告诉我们：安装 30 天内你的哪条规则最常触发？那是决定 `examples/` 要出什么样板的最好信号。
