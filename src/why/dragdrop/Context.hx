package why.dragdrop;

import tink.s2d.Point;
import tink.state.Observable;
import tink.state.State;

@:allow(why.dragdrop)
class Context<Item, Result> {
	final registry:Registry<Item, Result>;

	// drag operation
	final _itemType:Observable<SourceType>;
	final _item:Observable<Item>;
	final _sourceId:Observable<SourceId>;
	final _targetIds:Observable<ImmutableArray<TargetId>>;
	final _dropResult:Observable<Result>;
	final _didDrop:Observable<Bool>;
	final _isSourcePublic:Observable<Bool>;
	final __itemType:State<SourceType>;
	final __item:State<Item>;
	final __sourceId:State<SourceId>;
	final __targetIds:State<ImmutableArray<TargetId>>;
	final __dropResult:State<Result>;
	final __didDrop:State<Bool>;
	final __isSourcePublic:State<Bool>;

	// drag offset
	final _initialPosition:Observable<Point>;
	final _initialSourcePosition:Observable<Point>;
	final _position:Observable<Point>;
	final __initialPosition:State<Point>;
	final __initialSourcePosition:State<Point>;
	final __position:State<Point>;

	public function new(registry) {
		this.registry = registry;

		_itemType = __itemType = new State(null);
		_item = __item = new State(null);
		_sourceId = __sourceId = new State(null);
		_targetIds = __targetIds = new State<ImmutableArray<TargetId>>([]);
		_dropResult = __dropResult = new State(null);
		_didDrop = __didDrop = new State(false);
		_isSourcePublic = __isSourcePublic = new State(false);
		_initialPosition = __initialPosition = new State(null);
		_initialSourcePosition = __initialSourcePosition = new State(null);
		_position = __position = new State(null);
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

	/**
	 * Returns true if a drag operation is in progress, and either the owner initiated the drag, or its isDragging()
	 * is defined and returns true.
	 */
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

	/**
	 * Returns a string or an ES6 symbol identifying the type of the current dragged item. Returns null if no item is being dragged.
	 */
	public inline function getItemType():SourceType {
		return _itemType.value;
	}

	/**
	 * Returns a plain object representing the currently dragged item. Every drag source must specify it by returning an object
	 * from its beginDrag() method. Returns null if no item is being dragged.
	 */
	public inline function getItem():Item {
		return _item.value;
	}

	public inline function getSourceId():SourceId {
		return _sourceId.value;
	}

	public inline function getTargetIds():ImmutableArray<TargetId> {
		return _targetIds.value;
	}

	/**
	 * Returns a plain object representing the last recorded drop result. The drop targets may optionally specify it by returning an
	 * object from their drop() methods. When a chain of drop() is dispatched for the nested targets, bottom up, any parent that
	 * explicitly returns its own result from drop() overrides the child drop result previously set by the child. Returns null if
	 * called outside endDrag().
	 */
	public inline function getDropResult():Result {
		return _dropResult.value;
	}

	/**
	 * Returns true if some drop target has handled the drop event, false otherwise. Even if a target did not return a drop result,
	 * didDrop() returns true. Use it inside endDrag() to test whether any drop target has handled the drop. Returns false if called
	 * outside endDrag().
	 */
	public inline function didDrop():Bool {
		return _didDrop.value;
	}

	public inline function isSourcePublic():Bool {
		return _isSourcePublic.value;
	}

	/**
	 * Returns the { x, y } client offset of the pointer at the time when the current drag operation has started.
	 * Returns null if no item is being dragged.
	 */
	public inline function getInitialPosition():Point {
		return _initialPosition.value;
	}

	/**
	 * Returns the { x, y } client offset of the drag source component's root DOM node at the time when the current drag
	 * operation has started. Returns null if no item is being dragged.
	 */
	public function getInitialSourcePosition():Point {
		return _initialSourcePosition.value;
	}

	/**
	 * Returns the last recorded { x, y } client offset of the pointer while a drag operation is in progress.
	 * Returns null if no item is being dragged.
	 */
	public inline function getPosition():Point {
		return _position.value;
	}

	/**
	 * Returns the projected { x, y } client offset of the drag source component's root DOM node, based on its position at the time
	 * when the current drag operation has started, and the movement difference. Returns null if no item is being dragged.
	 */
	public function getSourcePosition():Point {
		return switch [getPosition(), getInitialSourcePosition(), getInitialPosition()] {
			case [null, _, _] | [_, null, _] | [_, _, null]: null;
			case [a, b, c]: a + b - c;
		}
	}

	/**
	 * Returns the { x, y } difference between the last recorded client offset of the pointer and the client offset when the current
	 * drag operation has started. Returns null if no item is being dragged.
	 */
	public inline function getDifferenceFromInitialPosition():Point {
		return getPosition() - getInitialPosition();
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

	public function getDroppableTargets():ImmutableArray<TargetId> {
		return getTargetIds().filter(canDropOnTarget).reverse();
	}
}
