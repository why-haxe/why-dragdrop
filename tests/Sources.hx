package;

import why.dragdrop.*;

class SourceBase implements DragSource<Any, Any> {
	public function canDrag(context:Context<Any, Any>, sourceId:SourceId):Bool {
		return true;
	}

	public function isDragging(context:Context<Any, Any>, sourceId:SourceId):Bool {
		return sourceId == context.getSourceId();
	}

	public function beginDrag(context:Context<Any, Any>, sourceId:SourceId):Any {
		return null;
	}

	public function endDrag(context:Context<Any, Any>, sourceId:SourceId):Void {
		// empty on purpose
	}
}

class NormalSource extends SourceBase {
	public var didCallBeginDrag = false;
	public var recordedDropResult:Any;
	public var item:Any;

	public function new(?item:Any) {
		this.item = item;
		if (this.item == null)
			this.item = {baz: 42}
	}

	override function beginDrag(context:Context<Any, Any>, sourceId:SourceId):Any {
		didCallBeginDrag = true;
		return this.item;
	}

	override function endDrag(context:Context<Any, Any>, sourceId:SourceId):Void {
		this.recordedDropResult = context.getDropResult();
	}
}

class NonDraggableSource extends SourceBase {
	public var didCallBeginDrag = false;

	public function new() {}

	override function canDrag(context:Context<Any, Any>, sourceId:SourceId) {
		return false;
	}

	override function beginDrag(context:Context<Any, Any>, sourceId:SourceId):Any {
		didCallBeginDrag = true;
		return {};
	}
}

class BadItemSource extends SourceBase {
	public function new() {}

	override function beginDrag(context:Context<Any, Any>, sourceId:SourceId):Any {
		return 42;
	}
}

class NumberSource extends SourceBase {
	public var number:Float;
	public var allowDrag:Bool;

	public function new(number:Float, allowDrag:Bool) {
		this.number = number;
		this.allowDrag = allowDrag;
	}

	override function canDrag(context:Context<Any, Any>, sourceId:SourceId):Bool {
		return this.allowDrag;
	}

	override function isDragging(context:Context<Any, Any>, sourceId:SourceId):Bool {
		final item = context.getItem();
		return (cast item).number == this.number;
	}

	override function beginDrag(context:Context<Any, Any>, sourceId:SourceId):Any {
		return {
			number: this.number,
		}
	}
}
