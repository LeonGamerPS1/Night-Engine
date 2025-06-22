package objects;

typedef CharacterData =
{
	var icon:String;
	var texture:String;

	var cameraOffset:{x:Float, y:Float};
	var positionOffset:{x:Float, y:Float};
	var scale:Float;

	var flipX:Bool;
	var dancer:Bool;
	var antialiasing:Bool;

	var holdSteps:Float;
	var animations:Array<CharacterAnimation>;
}

typedef CharacterAnimation = AnimationData &
{
	var offset:{x:Float, y:Float};
}

class BaseCharacter extends FlxSprite
{
	public var offsets:Map<String, {x:Float, y:Float}> = [];
	public var curCharacter = '';
	public var isPlayer:Bool = false;
	public var json:CharacterData;
	public var dancer = false;
	public var holdTimer:Float = 0;

	public function new(char:String = 'default', isPlayer:Bool = false)
	{
		super();
		this.curCharacter = char;
		this.isPlayer = isPlayer;
		loadJSON(char);
	}

	public function loadJSON(char:String = 'default')
	{
		this.json = null;
		frames = null;
		offsets.clear();

		var path = Paths.getPath('characters/$char.json');

		if (!Paths.exists(path))
			path = Paths.getPath('characters/bf.json');
		trace(path);

		this.json = cast Json.parse(Paths.getText(path));
		frames = Paths.getAtlas(json.texture);
		this.dancer = json.dancer;
		this.antialiasing = json.antialiasing;

		for (animData in json.animations)
		{
			if (animData.indices != null && animData.indices.length > 0)
				animation.addByIndices(animData.name, animData.prefix, animData.indices, '', animData.fps, animData.looped, animData.flipX, animData.flipY);
			else
				animation.addByPrefix(animData.name, animData.prefix, animData.fps, animData.looped, animData.flipX, animData.flipY);
			offsets.set(animData.name, animData.offset);
		}
		playAnim(!dancer ? 'idle' : 'danceLeft');
		scale.set(json.scale, json.scale);
		updateHitbox();
		playAnim(!dancer ? 'idle' : 'danceLeft');
		flipX = (json.flipX != isPlayer);
	}

	public function playAnim(anim:String = "idle", ?force:Bool = false)
	{
		animation.play(anim, force);
		if (offsets.exists(anim))
			offset.set(offsets[anim].x, offsets[anim].y);
	}

	public static var SingAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public function sing(note:Note)
	{
		if (note != null)
			playAnim(SingAnimations[note.noteData.data % SingAnimations.length], true);
		holdTimer = Conductor.instance.stepCrochet * json.holdSteps / 1000;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (holdTimer > 0)
		{
			holdTimer -= elapsed;
			if (holdTimer < 0)
			{
				holdTimer = 0;
				playAnim(!dancer ? 'idle' : 'danceLeft');
			}
		}
	}

	public function dance(beat:Float)
	{
		if (dancer)
		{
			if (animation.curAnim.name != 'danceLeft' && holdTimer == 0)
				playAnim('danceLeft', true);
			else if (animation.curAnim.name == 'danceLeft' && holdTimer == 0)
				playAnim('danceRight', true);
		}
		else
		{
			if ((animation.finished) && holdTimer == 0)
				playAnim('idle', true);
		}
	}
}