package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public static var subdivs(default, null):Int = 1;
	public function new()
	{
		super();

		addChild(new FlxGame(0, 0, PlayState));
		addChild(new openfl.display.FPS(10, 10, 0xFFFFFFFF));
		FlxG.inputs.add( Controls.instance = new Controls('coolbatfnf'));
		
	}
}
