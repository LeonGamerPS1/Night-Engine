package scripting;

class BaseScript
{
	public var source:String;
	public var scriptName:String;
	@:isVar
	public var variables(get, default):Map<String, Dynamic> = [];

	// implement these yourself by extending

	public function load(path:String):Void {}

	public function dispose():Void {
        variables = null;
        scriptName = null;
        source = null;
    }

	public function call(n:String, args:Array<Dynamic>):Dynamic
	{ // Implement this yourself
		return null;
	}

	public function set(n:String, v:Dynamic):Void {}

	function get_variables():Map<String, Dynamic>
	{
		return variables;
	}

	@:noCompletion
	private function init():Void {}

	// each script type handles the loading on its own
	public function new(name:String, path:String)
	{
		this.scriptName = name;
		init();
		load(path);
	}
}
