package objects;

class Strum extends FlxSprite
{
	public var data:Int = 0;
	public var skin(default, set):String;
	public var downScroll:Bool = false;
	public var cover:SustainCover;
	public var strumLine:StrumLine;

	public function new(data:Int = 0, ?texture:String = "default")
	{
		super();
		this.data = data;
		this.skin = texture;

		reload();
		cover = new SustainCover(this);
	}

	function set_skin(value:String):String
	{
		skin = value;

		return skin = value;
	}

	public static var dirs:Array<String> = ['left', 'down', 'up', 'right'];

	public var skinData:Dynamic = null;

	public function reload()
	{
		var skinData = parseSkin(skin);
		this.skinData = skinData;
		frames = Paths.getAtlas('notes/$skin/notes');
		var fps:Float = skinData.fps ?? 24;
		animation.addByPrefix('static', dirs[data % dirs.length] + '0', fps);
		animation.addByPrefix('confirm', dirs[data % dirs.length] + ' confirm0', fps, false);
		animation.addByPrefix('press', dirs[data % dirs.length] + ' press0', fps, false);

		playAnim('static');

		scale.set(skinData.scale, skinData.scale);
		updateHitbox();
		antialiasing = skinData.antialiasing;
	}

	function parseSkin(skin:String)
	{
		var path = 'assets/images/notes/$skin/_meta.json';
		var jsonRaw:String = Paths.getText(path);
		return Json.parse(jsonRaw);
	}

	public function playAnim(n:String = 'static', ?force:Bool = false)
	{
		animation.play(n, force);

		centerOffsets();
		centerOrigin();
	}
}
