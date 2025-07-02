package objects;

import backend.Song.NoteData;
import flixel.system.FlxAssets;

class Note extends FlxSprite
{
	public var noteData:NoteData = null;
	public var skin(default, set):String;
	public var downScroll:Bool = false;
	public var set:FlxPoint = FlxPoint.get();
	public var strumLine:StrumLine;

	public var parent(default, default):Note;
	public var sustainAngle(get, default):Float = 90;
	public var flipSustain:Bool = false;
	public var speed:Float = 1;
	public var sustain:Sustain;

	public function new(noteData:NoteData, sus:Bool = false, ?prevNote:Note = null, ?texture:String = "default", ?strumLine:StrumLine)
	{
		super(-500);
		this.noteData = noteData;
		this.strumLine = strumLine;
		this.skin = texture;
		this.noteData = noteData;
		this.prevNote = prevNote;
		shader = new FlxShader();
		shader.glProgram;

		reload();
	}

	function set_skin(value:String):String
	{
		skin = value;

		return skin = value;
	}

	public static var dirs:Array<String> = ['purple', 'blue', 'green', 'red'];

	public function reload()
	{
		var skinData = parseSkin(skin);
		var data = noteData.data;
		this.skinData = skinData;
		frames = Paths.getAtlas('notes/$skin/notes');
		animation.addByPrefix('arrow', dirs[data % dirs.length] + '0');
		animation.addByPrefix('hold', dirs[data % dirs.length] + ' hold piece0', 24, false);
		animation.addByPrefix('end', dirs[data % dirs.length] + ' hold end0', 24, false);

		var sizeMult:Float = strumLine != null ? strumLine.size : 1;
		playAnim('arrow');

		scale.set(skinData.scale, skinData.scale);
		scale.x *= sizeMult;
		scale.y *= sizeMult;
		updateHitbox();
		antialiasing = skinData.antialiasing;
	}

	public var skinData(default, null):Dynamic;

	static function parseSkin(skin:String)
	{
		var path = 'assets/images/notes/$skin/_meta.json';
		var jsonRaw:String = Paths.getText(path);
		return Json.parse(jsonRaw);
	}

	public function playAnim(n:String = 'arrow', ?force:Bool = false)
	{
		animation.play(n, force);

		centerOffsets();
		centerOrigin();
	}

	public var prevNote:Note = null;
	public var wasGoodHit:Bool = false;
	public var multAlpha:Float = 1;
	public var ignoreNote:Bool = false;
	public var canBeHit:Bool = false;

	override function destroy()
	{
		set.put();
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		canBeHit = (noteData.time <= Conductor.instance.time + Conductor.safeZoneOffset * 0.5
			&& !(noteData.time <= Conductor.instance.time - Conductor.safeZoneOffset * 0.5));
	}

	var distance:Float = 3000;
	var multSpeed:Float = 1;

	public function followStrumNote(myStrum:Strum, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		speed = songSpeed * multSpeed;
		distance = (0.45 * (Conductor.instance.time - noteData.time) * speed);
		downScroll = myStrum.downScroll;
		if (!myStrum.downScroll)
			distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;

		angle = strumAngle;
		alpha = strumAlpha * multAlpha;
		x = strumX + set.x + Math.cos(angleDir) * distance;
		y = strumY + set.y + Math.sin(angleDir) * distance;
		
	}

	function get_sustainAngle():Float
	{
		return (sustainAngle + (parent.strumLine != null ? parent.strumLine.strums.members[parent.noteData.data].direction : 0)) - 90;
	}
}

class SustainShader extends FlxShader
{
	@:glFragmentSource('
        #pragma header

        uniform sampler2D sustainTexture;
        uniform sampler2D endTexture;
uniform float singleSustainLength;

// animation stuff
uniform bool isAnimated;
uniform vec4 frameUV;

        void main() {
vec2 uv = openfl_TextureCoordv;
            float scale = singleSustainLength / openfl_TextureSize.y;

vec2 sustainUV = vec2(uv.x, mod(uv.y, scale) / scale);

if (isAnimated) 
sustainUV = frameUV.xy + sustainUV * frameUV.zw;

            if (openfl_TextureCoordv.y >= 1.0 - scale)
                gl_FragColor = flixel_texture2D(endTexture, sustainUV);
            else
                gl_FragColor = flixel_texture2D(sustainTexture, sustainUV);
        }
    ')
	public function new()
	{
		super();
	}
}
