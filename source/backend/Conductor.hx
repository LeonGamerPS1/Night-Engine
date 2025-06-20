package backend;

import lime.app.Event;

/**
	The conductor. Steps, beats, and measures use floats because this class was carried over from the original version from fnf zenith.
	Also, time signature changing math was implemented here.
	Revamped math by sword_352: https://github.com/Sword352
**/
@:publicFields
class Conductor
{
	/**
		A signal that dispatches every step.
	**/
	var onStep:Event<Float->Void> = new Event<Float->Void>();

	/**
		A signal that dispatches every beat.
	**/
	var onBeat:Event<Float->Void> = new Event<Float->Void>();

	/**
		A signal that dispatches every measure.
	**/
	var onMeasure:Event<Float->Void> = new Event<Float->Void>();

	/**
		The time of a step.
	**/
	var stepCrochet(default, null):Float = 150;

	/**
		The time of a beat.
	**/
	var crochet(default, null):Float = 600;

	/**
		The time of a measure.
	**/
	var measureCrochet(default, null):Float = 2400;

	/**
		The time measured as the tempo of a song.
	**/
	var bpm(default, null):Float = 100;

	/**
		Whenever the conductor's active.
	**/
	var active:Bool;

	/**
		The conductor's time.
	**/
	var time(default, set):Float = 0;

	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = (safeFrames / 60) * 1000; // is calculated in create(), is safeFrames in milliseconds

	/**
		Set the conductor's time.
	**/
	function set_time(value:Float):Float
	{
		time = value;

		var calc = (time - offsetTime);
		_stepTracker = Math.ffloor(stepOffset + calc / stepCrochet);
		_beatTracker = Math.ffloor(beatOffset + calc / crochet);
		_measureTracker = Math.ffloor(measureOffset + calc / measureCrochet);

		if (active)
		{
			if (curStep != _stepTracker)
			{
				curStep = _stepTracker;
				onStep.dispatch(curStep);
			}

			if (curBeat != _beatTracker)
			{
				curBeat = _beatTracker;
				onBeat.dispatch(curBeat);
			}

			if (curMeasure != _measureTracker)
			{
				curMeasure = _measureTracker;
				onMeasure.dispatch(curMeasure);
			}
		}
		else
		{
			curStep = _stepTracker;
			curBeat = _beatTracker;
			curMeasure = _measureTracker;
		}

		return value;
	}

	/**
		The step counter.
	**/
	var curStep(default, null):Float = 0;

	/**
		The beat counter.
	**/
	var curBeat(default, null):Float = 0;

	/**
		The measure counter.
	**/
	var curMeasure(default, null):Float = 0;

	private var _stepTracker(default, null):Float = 0;
	private var _beatTracker(default, null):Float = 0;
	private var _measureTracker(default, null):Float = 0;

	private var stepOffset(default, null):Float = 0;
	private var beatOffset(default, null):Float = 0;
	private var measureOffset(default, null):Float = 0;

	/**
		The time offsetted for bpm changes or time signatures.
	**/
	private var offsetTime(default, null):Float = 0;

	/**
		The step count of a beat.
	**/
	var numerator:Float = 4;

	/**
		The beat count of a measure.
	**/
	var denominator:Float = 4;

	/**
		Change the conductor's beats per minute.
		This also includes time signatures.
		@param position The position you want to execute the event on.
		@param newBpm The new beats per minute.
		@param newNumerator The new steps of the time signature.
		@param newDenominator The new beats of the time signature.
	**/
	inline function changeBpmAt(position:Float, newBpm:Float = 0, newNumerator:Float = 4, newDenominator:Float = 4):Void
	{
		var calc = (position - offsetTime);
		stepOffset += calc / stepCrochet;
		beatOffset += calc / crochet;
		measureOffset += calc / measureCrochet;
		offsetTime = position;

		if (newBpm > 0)
		{
			bpm = newBpm;
			stepCrochet = (15000 / bpm);
		}

		crochet = stepCrochet * newNumerator;
		measureCrochet = crochet * newDenominator;

		numerator = newNumerator;
		denominator = newDenominator;
	}

	/**
		Resets the conductor.
	**/
	inline function reset(removeSignals:Bool = false):Void
	{
		if (removeSignals)
		{
			Conductor.instance.onBeat.removeAll();
			Conductor.instance.onStep.removeAll();
			Conductor.instance.onMeasure.removeAll();
		}
		stepOffset = beatOffset = measureOffset = offsetTime = time = 0.0;
		changeBpmAt(0);
	}

	static var instance:Conductor = new Conductor();

	/**
		Constructs a conductor.
		@param initialBpm The initial beats per minute.
	**/
	inline function new(initialBpm:Float = 100, initialNumerator:Float = 4, initialDenominator:Float = 4):Void
	{
		changeBpmAt(0, initialBpm, initialNumerator, initialDenominator);
		active = true;
	}
}