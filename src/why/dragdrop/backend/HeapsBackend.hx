package why.dragdrop.backend;

import h2d.Scene;
import h2d.Interactive;
import hxd.Event;
import tink.s2d.Point;

class HeapsBackend<Item, Result> implements Backend<Interactive> {
	final s2d:Scene;

	final sourceNodes:Map<SourceId, Interactive> = new Map();
	final targetNodes:Map<TargetId, Interactive> = new Map();

	final context:Context<Item, Result>;
	final actions:Actions;

	var moveStartSourceIds:Array<SourceId>;
	var dragOverTargetIds:Array<TargetId>;
	var mousePosition:Point;

	public function new(s2d, context, actions) {
		this.s2d = s2d;
		this.context = context;
		this.actions = actions;
	}

	public function setup():Void {
		s2d.addEventListener(handleGlobal);
	}

	public function teardown():Void {
		s2d.removeEventListener(handleGlobal);
	}

	public function connectDragSource(sourceId:SourceId, ?node:Interactive, options:Any):CallbackLink {
		function _handlePush(e:Event)
			handlePush(e, sourceId);

		sourceNodes.set(sourceId, node);
		node.propagateEvents = true;
		node.onPush = _handlePush;
		return () -> {
			sourceNodes.remove(sourceId);
			node.onPush = function(e) {};
		}
	}

	public function connectDragPreview(sourceId:SourceId, ?node:Interactive, options:Any):CallbackLink {
		return null;
	}

	public function connectDropTarget(targetId:TargetId, ?node:Interactive, options:Any):CallbackLink {
		function handler(e:Event) {
			switch e.kind {
				case EMove:
					if (!context.isDragging())
						return;
					if (node.isOver())
						handleMove(e, targetId);
				case _:
			}
		}

		targetNodes.set(targetId, node);
		node.propagateEvents = true;
		s2d.addEventListener(handler);

		return () -> {
			targetNodes.remove(targetId);
			s2d.removeEventListener(handler);
		}
	}

	public function profile():Map<String, Int> {
		return new Map();
	}

	function handleGlobal(e:Event) {
		switch e.kind {
			case EPush:
				mousePosition = Point.xy(e.relX, e.relY);
			case EMove:
				var position = Point.xy(e.relX, e.relY);
				if (!context.isDragging() && moveStartSourceIds != null) {
					actions.beginDrag(moveStartSourceIds, {
						clientOffset: mousePosition,
						getSourceClientOffset: id -> switch sourceNodes[id] {
							case null: null;
							case node: Point.xy(node.parent.x, node.parent.y);
						},
						publishSource: false,
					});
					moveStartSourceIds = null;
				}
				if (!context.isDragging())
					return;
				// final sourceNode = sourceNodes[context.getSourceId()];
				actions.publishDragSource();

				final dragOverTargetNodes = switch dragOverTargetIds {
					case null: [];
					case ids: ids.map(targetNodes.get).filter(node -> node != null);
				}

				final orderedDragOverTargetIds = dragOverTargetNodes.map(getTargetId);

				actions.hover(orderedDragOverTargetIds, {
					clientOffset: position,
				});

				dragOverTargetIds = null;
			case ERelease:
				moveStartSourceIds = null;
				dragOverTargetIds = null;
				if (!context.isDragging() || context.didDrop()) {
					return;
				}
				actions.drop({});
				actions.endDrag();
			case _:
		}
	}

	function handlePush(e:Event, sourceId:SourceId) {
		if (moveStartSourceIds == null)
			moveStartSourceIds = [];
		moveStartSourceIds.unshift(sourceId);
	}

	function handleMove(e:Event, targetId:TargetId) {
		if (dragOverTargetIds == null)
			dragOverTargetIds = [];

		dragOverTargetIds.unshift(targetId);
	}

	function getTargetId(node:Interactive) {
		for (id => stored in targetNodes)
			if (stored == node)
				return id;

		return null;
	}
}
