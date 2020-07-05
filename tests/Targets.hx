package;

import why.dragdrop.*;

class TargetBase implements DropTarget {
	public function canDrop(context:Context, targetId:TargetId):Bool {
		return true;
	}

	public function hover(context:Context, targetId:TargetId):Void {
		// empty on purpose
	}

	public function drop(context:Context, targetId:TargetId):Any {
		return null;
	}
}

class NormalTarget extends TargetBase {
	public var didCallDrop = false;
	public var didCallHover = false;
	public var dropResult:Any;

	public function new(?dropResult) {
		this.dropResult = dropResult;
		if (this.dropResult == null)
			this.dropResult = {foo: 'bar'}
	}

	override function hover(context:Context, targetId:TargetId):Void {
		didCallHover = true;
	}

	override function drop(context:Context, targetId:TargetId):Any {
		didCallDrop = true;
		return dropResult;
	}
}

class NonDroppableTarget extends TargetBase {
	public var didCallDrop = false;
	public var didCallHover = false;

	override function canDrop(context:Context, targetId:TargetId):Bool {
		return false;
	}

	override function hover(context:Context, targetId:TargetId):Void {
		this.didCallHover = true;
	}

	override function drop(context:Context, targetId:TargetId):Any {
		this.didCallDrop = true;
		return null;
	}
}

class TargetWithNoDropResult extends TargetBase {
	public var didCallDrop = false;
	public var didCallHover = false;

	override function hover(context:Context, targetId:TargetId):Void {
		this.didCallHover = true;
	}

	override function drop(context:Context, targetId:TargetId):Any {
		this.didCallDrop = true;
		return null;
	}
}

class BadResultTarget extends TargetBase {
	override function drop(context:Context, targetId:TargetId):Any {
		return 42;
	}
}

class TransformResultTarget extends TargetBase {
	public var didCallDrop = false;
	public var didCallHover = false;

	var transform:(input:Any) -> Any;

	override function new(transform) {
		this.transform = transform;
	}

	override function hover(context:Context, targetId:TargetId):Void {
		this.didCallHover = true;
	}

	override function drop(context:Context, targetId:TargetId):Any {
		this.didCallDrop = true;
		final dropResult = context.getDropResult();
		return transform(dropResult);
	}
}
