class HelperAI extends AIInfo {
	function GetAuthor()      { return "MANDO"; }
	function GetName()        { return "Helper"; }
	function GetDescription() { return "help your human"; }
	function GetVersion()     { return 1; }
	function GetDate()        { return "2020-01-22"; }
	function CreateInstance() { return "HelperAI"; }
	function GetShortName()	  { return "HELP"; }
	function GetAPIVersion()  { return "1.0"; }
	
	function GetSettings() {
	    /* AddSetting({name = "CargoLines", description = "Number of single track cargo lines to start with", min_value = 0, max_value = 20, easy_value = 5, medium_value = 10, hard_value = 20, custom_value = 10, flags = AICONFIG_INGAME}); */
	    /* AddSetting({name = "MaxBridgeLength", description = "Maximum bridge length", min_value = 0, max_value = 40, easy_value = 20, medium_value = 20, hard_value = 20, custom_value = 20, flags = AICONFIG_INGAME}); */
	    /* AddSetting({name = "JunctionNames", description = "Name junctions with waypoints", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = AICONFIG_BOOLEAN|AICONFIG_INGAME}); */
	    /* AddSetting({name = "ActivitySigns", description = "Place signs showing what ChooChoo is doing", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = AICONFIG_BOOLEAN|AICONFIG_INGAME}); */
	    /* AddSetting({name = "PathfinderMultiplier", description = "Pathfinder speed: higher values are faster, but less accurate", min_value = 1, max_value = 4, easy_value = 1, medium_value = 2, hard_value = 3, custom_value = 3, flags = AICONFIG_INGAME}); */
	    /* AddLabels("PathfinderMultiplier", {_1 = "Slow", _2 = "Medium", _3 = "Fast", _4 = "Very fast"}); */
	}
}

RegisterAI(HelperAI());
