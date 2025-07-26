package;

import flixel.FlxGame;
import lime.graphics.Image;
import openfl.display.Sprite;

class Main extends Sprite
{
	public static var subdivs(default, null):Int = 1;
	public function new()
	{
		super();
		Poly.handle();
		addChild(new FlxGame(0, 0, PlayState));
		addChild(new openfl.display.FPS(10, 10, 0xFFFFFFFF));
		FlxG.stage.window.setIcon(Image.fromBitmapData(Paths.image("icons/icon-bf").bitmap));
		FlxG.inputs.add( Controls.instance = new Controls('coolbatfnf'));
		
	}
}
