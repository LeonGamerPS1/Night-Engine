package scripting;


import rulescript.RuleScript;
import rulescript.interps.BytecodeInterp;
import rulescript.parsers.HxParser;

class HScript extends BaseScript
{
	@:noCompletion var program:RuleScript;

	override function init()
	{
		program = new RuleScript(new BytecodeInterp());
	}

	override function load(path:String)
	{
		if (!Paths.exists(path))
			throw 'hSCRIPT.$scriptName: File of Path "$path" does not exist or is null. Please make sure the file exists and try again. Double check everything pretty pleaseeeeee';
		program.getInterp(BytecodeInterp).staticOptimization = false;
		program.getParser(HxParser).allowAll();
		program.execute(Paths.getText(path));
		set('game',PlayState.self);
		set('addModifier', function(n:String)
		{
			PlayState.self.mod.addModifier(n);
		});
		set('setPercent', function(n:String, v:Float)
		{
			PlayState.self.mod.setPercent(n, v);
		});
	}

	override function set(n:String, v:Dynamic) {
		program.access.setVariable(n,v);
	}

	override function call(n:String, args:Array<Dynamic>):Dynamic
	{
		return program.access.callFunction(n,args);
	}

	public override function dispose():Void
	{
		super.dispose();
		program = null;
	}

	public override function get_variables():Map<String, Dynamic>
	{
		return (program != null ? program.access.getVariables() : variables);
	}
}
