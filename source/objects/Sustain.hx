package objects;

class Sustain extends TiledSprite
{
	var parent:Note;

	public function new(parent:Note)
	{
		super(-3000, 0);
		this.parent = parent;
		parent.sustain = this;

		init();
	}

	function init()
	{
		normal();
	}

	inline function normal()
	{
		frames = parent.frames;
		animation.copyFrom(parent.animation);

		animation.play('hold');
		setTail('end');
		updateHitbox();

        var mult:Float = parent.strumLine != null ? parent.strumLine.size : 1;
		setGraphicSize(width * parent.skinData.scale * mult, frameHeight * parent.skinData.sustainScale);
		updateHitbox();

		antialiasing = parent.antialiasing;
	}

	override function draw()
	{
		parent.visible = !parent.wasGoodHit;
		var length:Float = parent.noteData.length;

		if (parent.wasGoodHit)
			length -= Math.abs(parent.noteData.time - Conductor.instance.time);

		var expectedHeight:Float = (length * 0.45 * parent.speed);
		
		if (height != expectedHeight)
			this.height = Math.max(expectedHeight, 0);

		if (alpha != parent.alpha * 0.7)
			alpha = parent.alpha * 0.7;

		regenPos();

		super.draw();
	}

	public inline function regenPos()
	{
		setPosition(parent.x + ((parent.width - width) * 0.5), parent.y + (parent.height * 0.5));

		var calcAngle:Float = 0;
		calcAngle += parent.sustainAngle - 90;
		if (parent.downScroll)
		{
			angle = calcAngle + 180;
			y -= 40;
		
		}
		else
			angle = calcAngle;
	}
}