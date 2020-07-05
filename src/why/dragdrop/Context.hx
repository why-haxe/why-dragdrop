package why.dragdrop;

import tink.s2d.Point;
import tink.state.Observable;
import tink.state.State;

private typedef Item = Any;
private typedef DropResult = Any;

@:allow(why.dragdrop)
class Context implements IContext {
	final registry:Registry;

	// drag operation
	final _itemType:Observable<SourceType>;
	final _item:Observable<Item>;
	final _sourceId:Observable<SourceId>;
	final _targetIds:Observable<Array<TargetId>>;
	final _dropResult:Observable<DropResult>;
	final _didDrop:Observable<Bool>;
	final _isSourcePublic:Observable<Bool>;
	final __itemType:State<SourceType>;
	final __item:State<Item>;
	final __sourceId:State<SourceId>;
	final __targetIds:State<Array<TargetId>>;
	final __dropResult:State<DropResult>;
	final __didDrop:State<Bool>;
	final __isSourcePublic:State<Bool>;

	// drag offset
	final _initialClientOffset:Observable<Point>;
	final _initialSourceClientOffset:Observable<Point>;
	final _clientOffset:Observable<Point>;
	final __initialClientOffset:State<Point>;
	final __initialSourceClientOffset:State<Point>;
	final __clientOffset:State<Point>;

	public function new(registry:Registry) {
		this.registry = registry;

		_itemType = __itemType = new State(null);
		_item = __item = new State(null);
		_sourceId = __sourceId = new State(null);
		_targetIds = __targetIds = new State([]);
		_dropResult = __dropResult = new State(null);
		_didDrop = __didDrop = new State(false);
		_isSourcePublic = __isSourcePublic = new State(false);
		_initialClientOffset = __initialClientOffset = new State(null);
		_initialSourceClientOffset = __initialSourceClientOffset = new State(null);
		_clientOffset = __clientOffset = new State(null);
	}

	public function canDragSource(sourceId:SourceId):Bool {
		return if (sourceId == null) false else switch registry.getSource(sourceId) {
			case null: false;
			case source:
				if (isDragging()) false else source.canDrag(this, sourceId);
		}
	}

	public function canDropOnTarget(targetId:TargetId):Bool {
		return if (targetId == null) false else switch registry.getTarget(targetId) {
			case null: false;
			case _ if (!isDragging() || didDrop()): false;
			case target:
				final targetType = registry.getTargetType(targetId);
				final itemType = getItemType();
				return targetType.contains(itemType) && target.canDrop(this, targetId);
		}
	}

	public function isDragging():Bool {
		return getItemType() != null;
	}

	public function isDraggingSource(sourceId:SourceId):Bool {
		return if (sourceId == null) false else switch registry.getSource(sourceId) {
			case null: false;
			case _ if (!isDragging() || !isSourcePublic()): false;
			case source:
				final sourceType = registry.getSourceType(sourceId);
				final itemType = getItemType();
				return sourceType == itemType && source.isDragging(this, sourceId);
		}
	}

	public function isOverTarget(targetId:TargetId, ?options:{?shallow:Bool}):Bool {
		if (targetId == null || !isDragging())
			return false;

		final targetType = registry.getTargetType(targetId);
		final draggedItemType = getItemType();
		if (draggedItemType != null && !targetType.contains(draggedItemType))
			return false;

		final targetIds = getTargetIds();
		if (targetIds.length == 0)
			return false;

		return switch targetIds.indexOf(targetId) {
			case index if (options != null && options.shallow):
				index == targetIds.length - 1;
			case index:
				index > -1;
		}
	}

	public function getItemType():SourceType {
		return _itemType.value;
	}

	public function getItem():Any {
		return _item.value;
	}

	public function getSourceId():SourceId {
		return _sourceId.value;
	}

	public function getTargetIds():Array<TargetId> {
		return _targetIds.value;
	}

	public function getDropResult():Any {
		return _dropResult.value;
	}

	public function didDrop():Bool {
		return _didDrop.value;
	}

	public function isSourcePublic():Bool {
		return _isSourcePublic.value;
	}

	public function getInitialClientOffset():Point {
		return _initialClientOffset.value;
	}

	public function getInitialSourceClientOffset():Point {
		return _initialSourceClientOffset.value;
	}

	public function getClientOffset():Point {
		return _clientOffset.value;
	}

	public function getSourceClientOffset():Point {
		return getClientOffset() + getInitialSourceClientOffset() - getInitialClientOffset();
	}

	public function getDifferenceFromInitialOffset():Point {
		return getClientOffset() - getInitialClientOffset();
	}

	public function getDraggableSource(sourceIds:Array<SourceId>):SourceId {
		var i = sourceIds.length - 1;
		while (i >= 0) {
			final id = sourceIds[i];
			if (canDragSource(id))
				return id;
			i--;
		}
		return null;
	}

	public function getDroppableTargets():Array<TargetId> {
		final targetIds = getTargetIds().filter(canDropOnTarget);
		targetIds.reverse();
		return targetIds;
	}
}

interface IContext {
	// subscribeToStateChange(
	// 	listener: Listener,
	// 	options?: {
	// 		handlerIds: Identifier[]
	// 	},
	// ): Unsubscribe
	// subscribeToOffsetChange(listener: Listener): Unsubscribe
	function canDragSource(sourceId:SourceId):Bool;
	function canDropOnTarget(targetId:TargetId):Bool;

	/**
	 * Returns true if a drag operation is in progress, and either the owner initiated the drag, or its isDragging()
	 * is defined and returns true.
	 */
	function isDragging():Bool;

	function isDraggingSource(sourceId:SourceId):Bool;
	function isOverTarget(targetId:TargetId, ?options:{?shallow:Bool}):Bool;

	/**
	 * Returns a string or an ES6 symbol identifying the type of the current dragged item. Returns null if no item is being dragged.
	 */
	function getItemType():SourceType;

	/**
	 * Returns a plain object representing the currently dragged item. Every drag source must specify it by returning an object
	 * from its beginDrag() method. Returns null if no item is being dragged.
	 */
	function getItem():Any;

	function getSourceId():SourceId;
	function getTargetIds():Array<TargetId>;

	/**
	 * Returns a plain object representing the last recorded drop result. The drop targets may optionally specify it by returning an
	 * object from their drop() methods. When a chain of drop() is dispatched for the nested targets, bottom up, any parent that
	 * explicitly returns its own result from drop() overrides the child drop result previously set by the child. Returns null if
	 * called outside endDrag().
	 */
	function getDropResult():Any;

	/**
	 * Returns true if some drop target has handled the drop event, false otherwise. Even if a target did not return a drop result,
	 * didDrop() returns true. Use it inside endDrag() to test whether any drop target has handled the drop. Returns false if called
	 * outside endDrag().
	 */
	function didDrop():Bool;

	function isSourcePublic():Bool;

	/**
	 * Returns the { x, y } client offset of the pointer at the time when the current drag operation has started.
	 * Returns null if no item is being dragged.
	 */
	function getInitialClientOffset():Point;

	/**
	 * Returns the { x, y } client offset of the drag source component's root DOM node at the time when the current drag
	 * operation has started. Returns null if no item is being dragged.
	 */
	function getInitialSourceClientOffset():Point;

	/**
	 * Returns the last recorded { x, y } client offset of the pointer while a drag operation is in progress.
	 * Returns null if no item is being dragged.
	 */
	function getClientOffset():Point;

	/**
	 * Returns the projected { x, y } client offset of the drag source component's root DOM node, based on its position at the time
	 * when the current drag operation has started, and the movement difference. Returns null if no item is being dragged.
	 */
	function getSourceClientOffset():Point;

	/**
	 * Returns the { x, y } difference between the last recorded client offset of the pointer and the client offset when the current
	 * drag operation has started. Returns null if no item is being dragged.
	 */
	function getDifferenceFromInitialOffset():Point;
}
