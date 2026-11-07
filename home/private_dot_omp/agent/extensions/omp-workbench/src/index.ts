/**
 * omp-workbench — a session workbench and an editor surface for omp.
 *
 * `/workbench` opens a full-screen workbench over the session list: filter
 * sessions, read their transcript outline, switch to one, delete one.
 * `/editor` opens a full-screen view with Files, Git, Sessions, and Jobs
 * pages; the Files page is a project tree that launches files in your
 * editor. Other plugins can add pages through the editor registry.
 *
 * Both surfaces paint on the terminal's alternate screen, so the conversation
 * on the normal screen stays untouched and the session keeps working.
 */
import type {
	ExtensionAPI,
	ExtensionCommandContext,
	ExtensionContext,
	ExtensionCustomOptions,
} from "@oh-my-pi/pi-coding-agent";
import { WorkbenchPanel } from "./workbench/workbench";
import { EditorPanel } from "./editor/panel";
import { installEditorApi, listEditorTabs } from "./editor/registry";
import type { EditorTabDefinition } from "./editor/tab";
import { FilesTab } from "./editor/tabs/files";
import { GitTab } from "./editor/tabs/git";
import { SessionsTab } from "./editor/tabs/sessions";
import { JobsTab } from "./editor/tabs/jobs";
import { deleteSessionFile, type SessionHost } from "./sessions/host";

const BUILTIN_TABS: readonly EditorTabDefinition[] = [
	{ id: "files", label: "Files", create: context => new FilesTab(context) },
	{ id: "git", label: "Git", create: context => new GitTab(context) },
	{ id: "sessions", label: "Sessions", create: context => new SessionsTab(context) },
	{ id: "jobs", label: "Jobs", create: context => new JobsTab(context) },
];

/** Covers the whole page on the alternate screen; the transcript is untouched. */
const FULLSCREEN_OVERLAY: ExtensionCustomOptions = {
	overlay: true,
	overlayOptions: {
		fullscreen: true,
		anchor: "top-left",
		width: "100%",
		maxHeight: "100%",
		mouseTracking: false,
	},
};

function isInteractive(ctx: ExtensionContext): boolean {
	return ctx.mode === "tui" && ctx.hasUI;
}

export default function workbenchExtension(pi: ExtensionAPI): void {
	pi.setLabel("Workbench");
	installEditorApi();

	/** A host that can switch sessions; command contexts provide the action. */
	const commandHost = (ctx: ExtensionCommandContext): SessionHost => ({
		ctx,
		switchSession: path => ctx.switchSession(path),
		dropSession: path => deleteSessionFile(path),
	});

	/** A host without session actions; shortcut handlers only get the plain context. */
	const readonlyHost = (ctx: ExtensionContext): SessionHost => ({ ctx });

	// The shortcuts toggle their surface: the second press closes it.
	let workbenchPanel: WorkbenchPanel | undefined;
	let editorPanel: EditorPanel | undefined;

	const openWorkbench = async (ctx: ExtensionContext, host: SessionHost): Promise<void> => {
		if (!isInteractive(ctx)) return;
		await ctx.ui.custom<undefined>(
			(tui, theme, _keybindings, done) => {
				workbenchPanel = new WorkbenchPanel({
					host,
					tui,
					theme,
					done: () => done(undefined),
				});
				return workbenchPanel;
			},
			FULLSCREEN_OVERLAY,
		);
		workbenchPanel = undefined;
	};

	const openEditor = async (ctx: ExtensionContext, host: SessionHost): Promise<void> => {
		if (!isInteractive(ctx)) return;
		const definitions = [...BUILTIN_TABS, ...listEditorTabs()];
		await ctx.ui.custom<undefined>(
			(tui, theme, _keybindings, done) => {
				editorPanel = new EditorPanel({
					host,
					tui,
					theme,
					done: () => done(undefined),
					exec: (command, args, options) => pi.exec(command, args, options),
					tabDefinitions: definitions,
				});
				return editorPanel;
			},
			FULLSCREEN_OVERLAY,
		);
		editorPanel = undefined;
	};

	pi.registerCommand("workbench", {
		description: "Open the session workbench (browse, inspect, switch sessions)",
		handler: async (_args, ctx) => {
			await openWorkbench(ctx, commandHost(ctx));
		},
	});

	pi.registerCommand("editor", {
		description: "Open the editor surface (project tree, git, sessions, jobs)",
		handler: async (_args, ctx) => {
			await openEditor(ctx, commandHost(ctx));
		},
	});

	pi.registerShortcut("alt+w", {
		description: "Toggle the session workbench",
		handler: async ctx => {
			if (workbenchPanel) {
				workbenchPanel.close();
				return;
			}
			await openWorkbench(ctx, readonlyHost(ctx));
		},
	});

	pi.registerShortcut("alt+b", {
		description: "Toggle the editor surface",
		handler: async ctx => {
			if (editorPanel) {
				editorPanel.close();
				return;
			}
			await openEditor(ctx, readonlyHost(ctx));
		},
	});
}
