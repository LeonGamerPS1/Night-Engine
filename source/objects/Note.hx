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

	public function new(noteData:NoteData, sus:Bool = false, ?prevNote:Note = null, ?texture:String = "default")
	{
		super(-500);
		this.noteData = noteData;
		this.skin = texture;
		this.noteData = noteData;
		this.prevNote = prevNote;
		this.isSustainNote = sus;
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

		playAnim('arrow');

		scale.set(skinData.scale, skinData.scale);
		updateHitbox();
		antialiasing = skinData.antialiasing;

		if (prevNote != null && isSustainNote)
		{
			set.x += width / 2;
			playAnim('end');
			updateHitbox();

			updateHitbox();
			antialiasing = skinData.antialiasing;

			set.x -= width / 2;

			if (prevNote.isSustainNote)
			{
				prevNote.antialiasing = false;
				prevNote.playAnim('hold');
				prevNote.scale.y = (prevNote.skinData.sustainScale) * Conductor.instance.stepCrochet / 100 * 1.470 * PlayState.song.speed;
				prevNote.updateHitbox();
			}
		}
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

	public var isSustainNote:Bool = false;
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

	public function clipToStrumNote(myStrum:Strum)
	{
		var mustPress = strumLine.cpu;
		var center:Float = myStrum.y + set.y + myStrum.height / 2;
		flipY = isSustainNote && myStrum.downScroll;
		if ((mustPress || !ignoreNote) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if (swagRect == null)
				swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if (y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	override function set_clipRect(r:FlxRect)
	{
		clipRect = r;
		if (frames != null)
			frame = frames.frames[animation.frameIndex];
		return clipRect = r;
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
