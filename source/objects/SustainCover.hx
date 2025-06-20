package objects;

class SustainCover extends FlxSprite
{
	public var parent:Strum;

	public function new(strum:Strum)
	{
		super();
		this.parent = strum;
		setup(strum);
	}

	public function setup(s)
	{
		var skinPath = 'notes/${parent.skin}/cover/${Note.dirs[parent.data % Note.dirs.length]}';

		if (Paths.exists('assets/images/notes/${parent.skin}/cover/cover.png'))
			skinPath = 'notes/${parent.skin}/cover/cover';
		var name = Note.dirs[parent.data % Note.dirs.length];
		frames = Paths.getAtlas(skinPath);
		animation.addByPrefix('start', 'start', 24);
		animation.addByPrefix('end', 'end', 24, false);
		animation.play('start');
		visible = false;
		animation.onFinish.add((_) ->
		{
			if (_ == 'end')
			{
				animation.play('start', true);
				visible = false;
			}
		});
	}

	override function draw()
	{
		scale.set(parent.skinData.cover.scaleX, parent.skinData.cover.scaleY);
		setPosition(parent.x + parent.skinData.cover.offsetX, parent.y + parent.skinData.cover.offsetY);
		super.draw();
	}
}
