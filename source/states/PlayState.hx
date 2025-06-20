package states;

import backend.Song;
import haxe.io.Path;
import lime.app.Application;
import lime.math.Rectangle;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class PlayState extends FlxState
{
	public var plrStrums:StrumLine;
	public var dadStrums:StrumLine;
	public var strumLines:Array<StrumLine> = [];

	public static var song:SongMap;

	public var camHUD:FlxCamera;
	public var ui:FlxGroup;

	public var startedCountdown:Bool = false;
	public var startedSong:Bool = false;
	public var songSpeed(default, set):Float = 1;
	public var downScroll(default, null):Bool = false;
	public var healthBar:FlxBar;
	public var healthBarBG:FlxSprite;
	public var health:Float = 1;
	public var scoreText:FlxText;
	
	public var score:Float = 0;
	public var misses:Int = 0;
	public var accuracy:Null<Float>;

	override public function create()
	{
		super.create();
		song ??= Song.grabSong();
		Conductor.instance.reset(true);
		Conductor.instance.changeBpmAt(0, song.bpm, 4, 4);
		Conductor.instance.time = -Conductor.instance.crochet * 5;
		Conductor.instance.onBeat.add(beat);
		Conductor.instance.onStep.add(step);
		Conductor.instance.onMeasure.add(section);

		var skin = 'default';
		if (song.skin != null && song.skin.length > 0)
			skin = song.skin;

		camHUD = new FlxCamera();
		camHUD.zoom = 1;
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		ui = new FlxGroup();
		ui.cameras = [camHUD];
		add(ui);

		dadStrums = new StrumLine((160 * 0.7 / 2) + 50, !downScroll ? 50 : FlxG.height - 150, downScroll, skin);
		strumLines.push(dadStrums);
		ui.add(dadStrums);

		plrStrums = new StrumLine(FlxG.width / 2 + (160 * 0.7 / 2), dadStrums.y, downScroll, skin);
		strumLines.push(plrStrums);
		plrStrums.cpu = false;
		ui.add(plrStrums);

		healthBarBG = new FlxSprite(0, !downScroll ? FlxG.height * 0.89 : 150, Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		ui.add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x, healthBarBG.y, RIGHT_TO_LEFT, Std.int(healthBarBG.width), Std.int(healthBarBG.height), this, 'health', 0, 2);
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		ui.insert(ui.members.indexOf(healthBarBG), healthBar);

		scoreText = new FlxText(healthBar.x + healthBar.width - 190, healthBar.y + 30, 0, 'Score: 0 // Misses: 0 // Rating: 0% (Unjudged)', 20);
		scoreText.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.borderSize = 1;
		scoreText.screenCenter(X);
		ui.add(scoreText);

		songSpeed = song.speed;

		for (iss in strumLines)
		{
			iss.missSignal = miss;
			iss.hitSignal = hit;
		}
		genC();
		startCallback();
	}

	public function miss(id:Int = 0)
	{
		misses++;
		score -= 150.5;
		health -= 0.05;
	}

	public function hit(note:Note)
	{
		if (note.strumLine != null && !note.strumLine.cpu && !note.isSustainNote)
		{
			score += 350.1;
			health += 0.04;
		}
	}

	function genC()
	{
		for (noteData in song.notes)
		{
			var oldNote = strumLines[noteData.strumLine].unspawnNotes[strumLines[noteData.strumLine].unspawnNotes.length - 1];
			var note:Note = new Note(noteData, false, oldNote, strumLines[noteData.strumLine].strums.members[noteData.data].skin);
			strumLines[noteData.strumLine].unspawnNotes.push(note);

			if (noteData.length > 0)
			{
				for (i in 0...Math.floor(noteData.length / Conductor.instance.stepCrochet + 1))
				{
					oldNote = strumLines[noteData.strumLine].unspawnNotes[strumLines[noteData.strumLine].unspawnNotes.length - 1];
					var sustain:Note = new Note({
						time: noteData.time + (Conductor.instance.stepCrochet * i) + (Conductor.instance.stepCrochet / songSpeed),
						data: noteData.data,
						type: noteData.type,
						strumLine: noteData.strumLine,
						length: 0
					}, true, oldNote, note.skin);
					strumLines[noteData.strumLine].unspawnNotes.push(sustain);
				}
			}
		}
	}

	public var tracks:Map<String, FlxSound> = [];

	public dynamic function startCallback():Void
		startCountdown();

	public var screenshotSPR:Bitmap;
	public var g = false;

	override public function update(elapsed:Float)
	{
		#if sys
		if (FlxG.keys.justPressed.F2)
		{
			var img = Application.current.window.readPixels(new Rectangle(FlxG.scaleMode.offset.x, FlxG.scaleMode.offset.y, FlxG.scaleMode.gameSize.x,
				FlxG.scaleMode.gameSize.y));
			var bytes = img.encode(PNG);
			if (!FileSystem.exists('screenshots'))
				FileSystem.createDirectory('screenshots');
			var date = Paths.sanitizeFilename(Date.now().toString());
			File.saveBytes('screenshots/Screenshot-$date.png', bytes);
			camHUD.flash();
			screenshotSPR ??= new Bitmap(BitmapData.fromImage(img));
			screenshotSPR.bitmapData = BitmapData.fromImage(img);
			screenshotSPR.bitmapData.disposeImage();
			if (!g)
				FlxG.stage.addChild(screenshotSPR);
			g = true;
			screenshotSPR.alpha = 1;
			screenshotSPR.scaleX = 0.5;
			screenshotSPR.scaleY = 0.5;
			FlxTween.tween(screenshotSPR, {alpha: 0}, 1);
		}
		#end
		health = FlxMath.bound(health, 0, 2);
		score = FlxMath.roundDecimal(score, 2);
		var scoreString:String = 'Score: $score // Misses: $misses // Rating: 0% (Unjudged, YOU SUCK!)';
		scoreText.text = scoreString;
		scoreText.screenCenter(X);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 5));
		if (!startedSong)
		{
			if (startedCountdown)
			{
				Conductor.instance.time += FlxG.elapsed * 1000;
				if (Conductor.instance.time > -0)
					startSong();
			}
		}
		else
			Conductor.instance.time = tracks.get('main').time;

		for (_ in tracks)
			if (_ != tracks.get('main') && Math.abs(_.time - tracks.get('main').time) > 40)
				_.time = tracks.get('main').time;
		super.update(elapsed);
	}

	function startSong()
	{
		startedSong = true;

		trace(tracks);
		for (_ in tracks)
			_.play();
	}

	public function startCountdown()
	{
		startedCountdown = true;
		tracks.set('main', FlxG.sound.load(Paths.getAssetPath(song.tracks.main)));
		for (track_ in song.tracks.extra)
		{
			if (!Paths.exists(Paths.getAssetPath(track_)))
				continue;
			tracks.set(track_, FlxG.sound.load(Paths.getAssetPath(track_)));
		}
	}

	function set_songSpeed(value:Float):Float
	{
		for (i in strumLines)
			i.songSpeed = value;
		return songSpeed = value;
	}

	public function step(val:Float) {}

	public function beat(val:Float) {}

	public function section(val:Float)
	{
		camHUD.zoom += 0.04;
	}
}
