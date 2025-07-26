package backend;

import polymod.Polymod;

/**
 * The `Poly` class is responsible for initializing and managing mod support
 * in the application using the PolyMod framework. It sets up the mod
 * environment and loads any mods found in the specified directories.
 */
class Poly
{
	/**
	 * Root directory where all mods are located.
	 * 
	 * This is a relative path from the application root to the folder where
	 * individual mod folders will be placed. PolyMod uses this root to search
	 * for mod directories specified in the `dirs` array during initialization.
	 * 
	 * Example:
	 * If MOD_ROOT is "./mods/" and a mod folder is "coolmod",
	 * PolyMod will look for it in "./mods/coolmod/".
	 */
	static inline var MOD_ROOT:String = "./mods/";

	/**
	 * Defines the expected API version for compatibility checks.
	 * 
	 * This version string may be used by mods to verify compatibility
	 * with the current application. It allows you to enforce that only
	 * mods targeting this version (or compatible versions) are loaded.
	 * 
	 * This version is arbitrary and project-defined. Changing it can
	 * be useful for signaling breaking changes in the mod API.
	 */
	static inline var API_VERSION_STRING:String = "0.1.0";

	/**
	 * Initializes the PolyMod system and loads mods.
	 * 
	 * This method serves as the main entry point for mod support in
	 * the application. It configures the PolyMod environment with the
	 * specified mod root and list of mod directories.
	 * 
	 * The `modFolders` array can be populated with folder names
	 * corresponding to individual mods. For now, it's left empty,
	 * but you can dynamically fill it based on available mods or
	 * user preferences.
	 * 
	 * PolyMod will look for each mod folder inside the `MOD_ROOT` directory.
	 * The `framework` parameter specifies which backend PolyMod should
	 * prepare for integration — in this case, `OPENFL`.
	 */
	public static function handle():Void
	{
		// List of mod directories to load.
		// Example: ["coolmod", "funnyweapons", "customlevels"]
		// These should exist within the MOD_ROOT directory.
		var modFolders:Array<String> = [
			// Add mod folder names here
		];
		for (mod in Polymod.scan({modRoot: MOD_ROOT}))
		{
			modFolders.push(mod.modPath.replace(MOD_ROOT, ""));
		}
		// Initialize PolyMod with the given configuration
		var mods = Polymod.init({
			modRoot: MOD_ROOT, // Root directory for mods
			framework: OPENFL, // Target framework (e.g., OPENFL or LIME)
			dirs: modFolders // List of subfolders to load as mods
		});

		for (mod in mods)
		{
			trace('Loaded mod: ${mod.title} (${mod.modVersion})');
		}
		trace('loaded ${mods.length} mods from ${MOD_ROOT}');
	}
}
