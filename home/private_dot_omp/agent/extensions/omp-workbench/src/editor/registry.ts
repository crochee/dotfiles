/**
 * Registry for the pages of the editor surface.
 *
 * Other plugins contribute a page by calling `registerEditorTab` (or the
 * `globalThis.ompWorkbench.registerTab` alias). The registry lives on
 * `globalThis` so every extension loaded into the process sees the same set.
 */
import type { EditorTabDefinition } from "./tab";

const REGISTRY_KEY = Symbol.for("omp.workbench.pages.registry");

interface RegistryHost {
	definitions: Map<string, EditorTabDefinition>;
}

type GlobalWithRegistry = typeof globalThis & {
	[REGISTRY_KEY]?: RegistryHost;
	ompWorkbench?: {
		registerTab(definition: EditorTabDefinition): () => void;
		listTabs(): EditorTabDefinition[];
	};
};

function host(): RegistryHost {
	const global = globalThis as GlobalWithRegistry;
	global[REGISTRY_KEY] ??= { definitions: new Map() };
	return global[REGISTRY_KEY];
}

/** Register a page; the returned function removes it again. */
export function registerEditorTab(definition: EditorTabDefinition): () => void {
	const registry = host();
	registry.definitions.set(definition.id, definition);
	return () => {
		registry.definitions.delete(definition.id);
	};
}

/** Every registered page, in registration order. */
export function listEditorTabs(): EditorTabDefinition[] {
	return [...host().definitions.values()];
}

/** Publish the registry on `globalThis` so other plugins can reach it. */
export function installEditorApi(): void {
	const global = globalThis as GlobalWithRegistry;
	global.ompWorkbench = {
		registerTab: registerEditorTab,
		listTabs: listEditorTabs,
	};
}
