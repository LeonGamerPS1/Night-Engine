package states;

import backend.Song;
import lime.app.Application;
import lime.math.Rectangle;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class PlayState extends FlxState implements IStageState
{
	public static var daPixelZoom(default, null):Float = 6;

	public var plrStrums:StrumLine;
	public var dadStrums:StrumLine;
	public var gfStrums:StrumLine;
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

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var jsStage:SceneData;
	public var defaultZoom:Float = 1.000;
	public var curStage:String = '?';
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public function stageLoad()
	{
		var path = Paths.getAssetPath('stages/${song.stage}.json');
		if (!Paths.exists(path))
			path = Paths.getAssetPath('stages/stage.json');

		jsStage = Json.parse(Paths.getText(path));
		BF_X = jsStage.bf.x;
		BF_Y = jsStage.bf.y;

		DAD_X = jsStage.dad.x;
		DAD_Y = jsStage.dad.y;

		GF_X = jsStage.gf.x;
		GF_Y = jsStage.gf.y;
		defaultZoom = jsStage.zoom;
		FlxG.camera.zoom = defaultZoom;
		curStage = path.replace('assets/stages/', '').replace('.json', '');
		trace(curStage);
		boyfriendCameraOffset = jsStage.bfCam;
		opponentCameraOffset = jsStage.dadCam;
		girlfriendCameraOffset = jsStage.gfCam;

		switch (curStage)
		{
			case 'stage':
				addStage(new objects.stages.Week1(this, true, null));

			case 'school':
				addStage(new objects.stages.Week6(this, true, null));
		}
		// call('onStageLoaded');
	}

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

		stageLoad();
		initchar();

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

		gfStrums = new StrumLine((160 * 0.7 / 2) + 5044, !downScroll ? 50 : FlxG.height - 150, downScroll, skin);
		strumLines.push(gfStrums);
		ui.add(gfStrums);

		healthBarBG = new FlxSprite(0, !downScroll ? FlxG.height * 0.89 : 150, Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		ui.add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x, healthBarBG.y, RIGHT_TO_LEFT, Std.int(healthBarBG.width), Std.int(healthBarBG.height), this, 'health', 0, 2);
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		ui.insert(ui.members.indexOf(healthBarBG), healthBar);

		iconP2 = new HealthIcon(dad.json.icon);
		iconP2.y = healthBar.y - 75;
		iconP2.x = healthBar.x + healthBar.width / 2 - iconP2.frameWidth - 10;
		ui.add(iconP2);

		iconP1 = new HealthIcon(bf.json.icon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.x = healthBar.x + healthBar.width / 2 + 10;
		ui.add(iconP1);

		
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
			Conductor.instance.onBeat.add(iss.beatHit);
		}
		plrStrums.character = bf;
		dadStrums.character = dad;
		gfStrums.character = gf;

		forEachStage((_) ->
		{
			_.createPost();
		});
		genC();

		startCallback();
	}

	public var bf:BaseCharacter;
	public var dad:BaseCharacter;
	public var gf:BaseCharacter;

	public var eventNotes:Array<Event> = [];

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].time;
			if (Conductor.instance.time < leStrumTime)
				return;

			triggerEvent(eventNotes[0]);
			eventNotes.shift();
		}
	}

	function initchar()
	{
		gf = new BaseCharacter(song.players[1], true);
		gf.setPosition(GF_X, GF_Y);
		gf.scrollFactor.set(0.95, 0.95);
		add(gf);

		dad = new BaseCharacter(song.players[0], false);
		dad.setPosition(DAD_X, DAD_Y);
		add(dad);

		bf = new BaseCharacter(song.players[2], true);
		bf.setPosition(BF_X, BF_Y);
		add(bf);

		if (gf.curCharacter == dad.curCharacter)
		{
			dad.setPosition(gf.x, gf.y);
			dad.flipX = false;
			dad.json = gf.json;
			gf.kill();
		}

		camFollow = new FlxObject(bf.x, bf.y);

		add(camFollow);
		FlxG.camera.follow(camFollow, LOCKON, 0.06);
		for (so in [dad, gf, bf])
		{
			so.x += so.json.positionOffset.x;
			so.y += so.json.positionOffset.y;
		}
		cam('dad');
		FlxG.camera.snapToTarget();
	}

	public function cam(target:String = 'dad')
	{
		switch (target.toLowerCase())
		{
			case 'dad' | 'opponent':
				if (dad == null)
					return;
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				camFollow.x += dad.json.cameraOffset.x + opponentCameraOffset[0];
				camFollow.y += dad.json.cameraOffset.y + opponentCameraOffset[1];
			case 'gf' | 'girlfriend':
				if (dad == null)
					return;
				camFollow.setPosition(gf.getMidpoint().x + 150, gf.getMidpoint().y - 100);
				camFollow.x += gf.json.cameraOffset.x + girlfriendCameraOffset[0];
				camFollow.y += gf.json.cameraOffset.y + girlfriendCameraOffset[1];
			case 'bf' | 'boyfriend':
				if (bf == null)
					return;

				camFollow.setPosition(bf.getMidpoint().x - 100, bf.getMidpoint().y - 100);
				camFollow.x -= bf.json.cameraOffset.x - boyfriendCameraOffset[0];
				camFollow.y += bf.json.cameraOffset.y + boyfriendCameraOffset[1];
		}
	}

	public var boyfriendCameraOffset:Array<Float> = [0, 0];
	public var opponentCameraOffset:Array<Float> = [0, 0];
	public var girlfriendCameraOffset:Array<Float> = [0, 0];

	public var camFollow:FlxObject;

	function triggerEvent(event:Event)
	{
		if (event.name == 'Camera Focus')
		{
			cam(event.values[0]);
		}
		if (event.name == 'Change Scroll Speed')
		{
			FlxTween.cancelTweensOf(this);
			FlxTween.tween(this, {songSpeed: event.values[0]}, event.values[1], {ease: FlxEase.sineInOut});
		}

		if (event.name == 'Change BPM')
			Conductor.instance.changeBpmAt(0, event.values[0], event.values[1], event.values[2]);
		if (event.name == 'Camera Zoom')
		{
			var fp1:Float = event.values[0] is String ? Std.parseFloat(event.values[0]) : event.values[0]; // event values are fucking strings sobbbbbb if you use legacy format like psych 0.7.3
			if (Math.isNaN(fp1))
				fp1 = 1; // jsStage.zoom;

			defaultZoom = fp1;
		}

		if (event.name == 'Add Camera Zoom')
		{
			var fp1:Float = event.values[0] is String ? Std.parseFloat(event.values[0]) : event.values[0]; // event values are fucking strings sobbbbbb if you use legacy format like psych 0.7.3
			if (Math.isNaN(fp1) || fp1 == 0)
				fp1 = 0.015;

			FlxG.camera.zoom += fp1;

			var fp2:Float = event.values[1] is String ? Std.parseFloat(event.values[1]) : event.values[1]; // event values are fucking strings sobbbbbb if you use legacy format like psych 0.7.3
			if (Math.isNaN(fp2) || fp2 == 0)
				fp2 = 0.03;

			camHUD.zoom += fp2;
		}

		if (event.name == 'Play Animation')
		{
			var char:BaseCharacter = dad;
			switch (event.values[1])
			{
				case 'dad' | 'Dad' | 'DAD' | 'opponent' | 'Opponent' | 'OPPONENT':
					char = dad;
				case 'bf' | 'Bf' | 'BF' | 'boyfriend' | 'Boyfriend' | 'BOYFRIEND':
					char = bf;
				case 'gf' | 'GF' | 'girlfriend' | 'Girlfriend' | 'GIRLFRIEND' | 'spectator' | 'Spectator' | 'Spectator':
					char = gf;
			}
			char.playAnim(event.values[0], true);
			char.holdTimer = char.animation.numFrames / char.animation.curAnim.frameRate;
		}
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
		for (_ in song.events)
			eventNotes.push(_);
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
		FlxG.camera.zoom = FlxMath.lerp(defaultZoom, FlxG.camera.zoom, Math.exp(-elapsed * 5));
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

		checkEventNote();
		for (_ in tracks)
			if (_ != tracks.get('main') && Math.abs(_.time - tracks.get('main').time) > 40)
				_.time = tracks.get('main').time;
		super.update(elapsed);
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var barCenter:Float = get_center();
		var iconOffset:Int = 26;
		iconP1.x = barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		forEachStage((_) ->
		{
			_.updatePost(elapsed);
		});
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

	public function step(val:Float)
	{
		forEachStage((_) ->
		{
			_.curStep = val;
			_.stepHit();
		});
	}

	public function beat(val:Float)
	{
		iconP1.scale.set(1.2, 1.2);
		iconP1.updateHitbox();

		iconP2.scale.set(1.2, 1.2);
		iconP2.updateHitbox();
		forEachStage((_) ->
		{
			_.curBeat = val;
			_.beatHit();
		});
	}

	public function section(val:Float)
	{
		FlxG.camera.zoom += 0.02;
		camHUD.zoom += 0.04;
		forEachStage((_) ->
		{
			_.curSection = val;
			_.sectionHit();
		});
	}

	public var stages:Array<BaseStage> = [];

	public function forEachStage(func_:BaseStage->Void):Void
	{
		if (func_ == null)
			return;
		for (i in 0...stages.length)
		{
			var stage:BaseStage = stages[i];
			func_(stage);
		}
	}

	public function addStage(stage:BaseStage)
	{
		if (!stages.contains(stage))
			stages.push(stage);
		add(stage);
	}

	function get_center():Float
	{
		return (healthBar != null ? healthBar.x - (healthBar.width * (healthBar.percent / 100)) + healthBar.width : 0);
	}
}
