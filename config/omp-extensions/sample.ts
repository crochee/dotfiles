/**
 * oh-my-pi 扩展样板（最小可用版）
 *
 * 加载链路验证：
 *   1. 文件位置：~/.omp/agent/extensions/sample.ts
 *      （或目录 ~/.omp/agent/extensions/sample-extension/，配合 package.json）
 *   2. 入口规则（loader.ts:116-131 / plugin-extensions-discovery.test.ts:162-163）：
 *        - 单文件：直接 import 该 .ts
 *        - 目录：优先 package.json 的 omp.extensions / pi.extensions；否则 index.ts
 *   3. default export 必须是 factory(pi: ExtensionAPI) => void
 *   4. 运行时：bun（oh-my-pi 自带 bun runtime，直接跑 .ts）
 *
 * 包来源：
 *   这些包随 oh-my-pi CLI 一起装在机器上（mise: github:can1357/oh-my-pi）。
 *   导入走 @oh-my-pi/* 命名空间；legacy @mariozeangler/pi-* 会被自动改写。
 *
 *   已知坑（loader.ts / issue #1514 / #4954）：
 *     - 编译版 omp 在 Windows 上 value import 可能失败 → 推荐 `import type` + 用 pi.* 内置方法
 *     - Linux/macOS 用户级扩展目录通常 OK
 *
 * 启用方式（手动，install.sh 不动）：
 *   # 方式 A：单文件符号链接
 *   mkdir -p ~/.omp/agent/extensions
 *   ln -sf ~/.dotfiles/config/omp-extensions/sample.ts \
 *          ~/.omp/agent/extensions/sample.ts
 *
 *   # 方式 B：整目录链接（推荐，package.json 会被 loader 识别）
 *   ln -sfn ~/.dotfiles/config/omp-extensions \
 *            ~/.omp/agent/extensions/sample-extension
 *   # 然后在扩展目录里 bun install 一次（装 @oh-my-pi/* 依赖供编辑器/类型解析）
 *   (cd ~/.omp/agent/extensions/sample-extension && bun install)
 *
 *   启动 omp 后，loader 会执行 default factory；本扩展在 session_start 时打一条日志，
 *   验证：~/.omp/logs/ 下能看到 "[sample] extension loaded"
 */

import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { formatDuration } from "@oh-my-pi/pi-utils";

export default function sample(pi: ExtensionAPI): void {
	pi.logger.info("[sample] extension loaded");

	pi.on("session_start", () => {
		// 用真包里的 formatDuration 验证 value import 通了
		const uptime = formatDuration(process.uptime() * 1000);
		pi.logger.info(`[sample] session_start, omp uptime=${uptime}`);
	});
}