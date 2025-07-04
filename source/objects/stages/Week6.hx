package objects.stages;

class Week6 extends BaseStage
{
	var bgGirls:BackgroundGirls;

	override function create()
	{
		var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
		add(bgSky);
		bgSky.antialiasing = false;

		var repositionShit = -200;

		var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
		add(bgSchool);
		bgSchool.antialiasing = false;

		var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
		add(bgStreet);
		bgStreet.antialiasing = false;

		var widShit = Std.int(bgSky.width * PlayState.daPixelZoom);
		var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);

		var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
		fgTrees.setGraphicSize(Std.int(widShit * 0.8));
		fgTrees.updateHitbox();
		add(fgTrees);
		fgTrees.antialiasing = false;

		bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
		bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		bgTrees.animation.play('treeLoop');
		bgTrees.scrollFactor.set(0.85, 0.85);
		add(bgTrees);
		bgTrees.antialiasing = false;

		var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
		treeLeaves.setGraphicSize(widShit);
		treeLeaves.updateHitbox();
		add(treeLeaves);
		treeLeaves.antialiasing = false;

		bgSky.setGraphicSize(widShit);
		bgSchool.setGraphicSize(widShit);
		bgStreet.setGraphicSize(widShit);
		bgTrees.setGraphicSize(Std.int(widShit * 1.4));

		bgSky.updateHitbox();
		bgSchool.updateHitbox();
		bgStreet.updateHitbox();
		bgTrees.updateHitbox();

		bgGirls = new BackgroundGirls(-100, 190);
		bgGirls.scrollFactor.set(0.9, 0.9);
		add(bgGirls);

		var songName = PlayState.song.songName.toLowerCase().replace(" ", "-");
		switch (songName)
		{
			case 'dreams-of-roses' | 'roses':
				//	FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));

				if (bgGirls != null)
					bgGirls.swapDanceType();
		}
	}

	override function beatHit()
	{
		if (bgGirls != null)
			bgGirls.dance();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	// For events
	function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch (eventName)
		{
			case "BG Freaks Expression":
				if (bgGirls != null)
					bgGirls.swapDanceType();
		}
	}
}

class BackgroundGirls extends FlxSprite
{
	var isPissed:Bool = true;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		// BG fangirls dissuaded
		frames = Paths.getSparrowAtlas('weeb/bgFreaks');
		antialiasing = false;
		swapDanceType();

		setGraphicSize(Std.int(width * PlayState.daPixelZoom));
		updateHitbox();
		animation.play('danceLeft');
	}

	var danceDir:Bool = false;

	public function swapDanceType():Void
	{
		isPissed = !isPissed;
		if (!isPissed)
		{ // Gets unpissed

			animation.addByPrefix('idle', 'BG girls group', 25, false);
		}
		else
		{ // Pisses

			animation.addByPrefix('idle', 'BG fangirls dissuaded', 25, false);
		}
		dance();
	}

	public function dance():Void
	{
		danceDir = !danceDir;


			animation.play('idle', true);

	}
}