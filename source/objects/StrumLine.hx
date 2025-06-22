package objects;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;

class StrumLine extends FlxSpriteGroup
{
	public var songSpeed:Float = 1;

	public var strums:FlxTypedSpriteGroup<Strum>;
	public var covers:FlxTypedSpriteGroup<SustainCover>;
	public var notes:FlxTypedSpriteGroup<Note>;

	public var unspawnNotes:Array<Note> = [];
	public var cpu = true;
	public var downScroll:Bool = false;
	public var sk = null;

	public function new(x:Float = 0, y:Float = 0, downScroll:Bool = false, skin:String = "default")
	{
		super(x, y);

		this.sk = skin;
		this.downScroll = downScroll;

		strums = new FlxTypedSpriteGroup<Strum>();
		add(strums);

		notes = new FlxTypedSpriteGroup<Note>();
		add(notes);

		covers = new FlxTypedSpriteGroup<SustainCover>();
		add(covers);

		generate();
	}

	function generate()
	{

		for (i in strums)
		{
			i.destroy();
			strums.remove(i, true);
			i = null;
		}

		for (i in covers)
		{
			i.destroy();
			covers.remove(i, true);
			i = null;
		}

		for (i in 0...4)
		{
			var strum:Strum = new Strum(i, sk);
			strum.downScroll = downScroll;
			strum.x = (160 * 0.7) * i;
			covers.add(strum.cover);
			strums.add(strum);
		}
	}

	public var character:BaseCharacter;

	override function update(elapsed:Float)
	{
		if (unspawnNotes[0] != null)
		{
			var time:Float = 3000;
			if (songSpeed < 1)
				time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].noteData.time - Conductor.instance.time < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				dunceNote.setPosition(-6666, 6666);
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
				// notes.sort(sortNotesByTimeHelper, FlxSort.DESCENDING);
			}
		}

		strums.forEachAlive(function(s)
		{
			if (s.animation.finished && cpu)
				s.playAnim('static');
		});

		super.update(elapsed);

		if (!cpu)
			keyPregnancy();

		notes.forEachAlive(function(note:Note)
		{
			var strum = strums.members[note.noteData.data % strums.length];

			note.x = strum.x + note.set.x;
			note.y = strum.y + (note.noteData.time - Conductor.instance.time) * (0.45 * songSpeed * (!strum.downScroll ? 1 : -1)) + note.set.y;
			note.alpha = strum.alpha * note.multAlpha;
			note.strumLine = this;

			if (cpu
				&& (note.noteData.time <= Conductor.instance.time
					|| note.isSustainNote
					&& note.prevNote.wasGoodHit
					&& note.noteData.time <= Conductor.instance.time + (Conductor.safeZoneOffset * 0.5))
				&& !note.wasGoodHit
				&& !note.ignoreNote)
			{
				note.wasGoodHit = true;
				hitSignal(note);
				strum.playAnim('confirm', !note.isSustainNote);
				if (character != null)
					character.sing(note);

				if (note.isSustainNote || note.noteData.length > 0 && !note.isSustainNote)
					strum.cover.visible = true;
				if (note.animation.name.contains('end'))
				{
					strum.cover.animation.play('end');
					strum.cover.visible = true;
					strum.playAnim('static', true);
				}

				if (!note.isSustainNote)
					invalNote(note);
			}

			if (note.isSustainNote)
				note.clipToStrumNote(strum);

			if (note.noteData.time < Conductor.instance.time - (350 / songSpeed))
			{
				if (!cpu && !note.wasGoodHit && !note.ignoreNote)
					miss(note.noteData.data);

				invalNote(note);
			}
		});
	}

	function invalNote(note:Note)
	{
		note.destroy();
		notes.remove(note, true);
		note = null;
	}

	public var hitNotes:Array<Note> = [];
	public var directions:Array<Int> = [];

	inline public static function sortNotesByTimeHelper(Order:Int, Obj1:Note, Obj2:Note)
		return FlxSort.byValues(Order, Obj1.noteData.time, Obj2.noteData.time);

	var keyPress:Array<Bool> = [];
	var keyHold:Array<Bool> = [];
	var keyReleased:Array<Bool> = [];

	public function keyPregnancy():Void
	{
		hitNotes = [];
		directions = [];
		// fuck this  shitty function name!
		keyPress = [
			Controls.instance.justPressed.NOTE_LEFT,
			Controls.instance.justPressed.NOTE_DOWN,
			Controls.instance.justPressed.NOTE_UP,
			Controls.instance.justPressed.NOTE_RIGHT
		];
		keyHold = [
			Controls.instance.pressed.NOTE_LEFT,
			Controls.instance.pressed.NOTE_DOWN,
			Controls.instance.pressed.NOTE_UP,
			Controls.instance.pressed.NOTE_RIGHT
		];

		keyReleased = [
			Controls.instance.justReleased.NOTE_LEFT,
			Controls.instance.justReleased.NOTE_DOWN,
			Controls.instance.justReleased.NOTE_UP,
			Controls.instance.justReleased.NOTE_RIGHT
		];

		if (keyHold.contains(true) && character != null && character.holdTimer < 0.04)
			character.holdTimer = 0.04;

		strums.forEachAlive(function(strum:Strum)
		{
			if (keyPress[strum.data])
				strum.playAnim('press', true);
			else if (keyReleased[strum.data])
			{
				strum.playAnim('static', false);
				if (strum.cover.animation.name != "end")
					strum.cover.visible = false;
			}
		});

		for (note in notes.members.filter((n:Note) -> return (n.canBeHit)))
		{
			hitNotes.push(note);
			directions.push(note.noteData.data);
		}

		if (hitNotes.length > 0)
		{
			for (shit in 0...keyPress.length)
				if (keyPress[shit] && !directions.contains(shit))
					miss(shit);

			for (shittNo in hitNotes)
			{
				if (!shittNo.wasGoodHit && keyPress[shittNo.noteData.data] && !shittNo.isSustainNote)
					playerHit(shittNo);

				if (!shittNo.wasGoodHit
					&& keyHold[shittNo.noteData.data]
					&& shittNo.isSustainNote
					&& (shittNo.canBeHit || shittNo.prevNote.wasGoodHit && shittNo.canBeHit))
					playerHit(shittNo);
			}
		}
	}

	public var missSignal = function(id:Int = 0) {};
	public var hitSignal = function(n:Note) {};

	function miss(shit:Int = 0)
	{
		missSignal(shit);
	}

	function playerHit(shittNo:Note)
	{
		var note = shittNo;
		shittNo.wasGoodHit = true;
		var strum = strums.members[shittNo.noteData.data % strums.length];
		strum.playAnim('confirm', !note.isSustainNote);
		hitSignal(shittNo);
		if (character != null)
			character.sing(shittNo);

		if (note.isSustainNote || note.noteData.length > 0 && !note.isSustainNote)
			strum.cover.visible = true;
		if (note.animation.name.contains('end'))
		{
			strum.cover.animation.play('end');
			strum.cover.visible = true;
			strum.playAnim('press', true);
		}

		if (!shittNo.isSustainNote)
			invalNote(shittNo);
	}
	public function beatHit(beat:Float)
	{
		if (character != null && (cpu || !cpu && !keyHold.contains(true)))
			character.dance(beat);
		notes.sort(sortNotesByTimeHelper, FlxSort.DESCENDING);
	}
}
