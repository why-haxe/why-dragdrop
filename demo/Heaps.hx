package;

import h2d.Interactive;
import h2d.Graphics;
import why.dragdrop.*;
import why.dragdrop.backend.*;
import tink.state.Observable;

using tink.CoreApi;

class Heaps extends hxd.App {
	static function main() {
		new Heaps();
	}

	override function init() {
		// setup drag/drop manager & backend
		final manager = new Manager(manager -> new HeapsBackend(s2d, manager.context, manager.actions));
		final backend = manager.backend;
		final registry = manager.registry;
		final context = manager.context;

		// create drag/drop handlers
		var sourceId1 = registry.addSource('DEFAULT', new MySource());
		var sourceId2 = registry.addSource('FOO', new MySource());
		var targetId1 = registry.addTarget(['DEFAULT'], new MyTarget());
		var targetId2 = registry.addTarget(['DEFAULT', 'FOO'], new MyTarget());

		// create sprites
		var target2 = makeSprite(200, 0, 300, 300, 0x0000ff);
		var target1 = makeSprite(300, 100, 100, 100, 0x00ff00);
		var source1 = makeSprite(0, 0, 100, 100, 0xff0000);
		var source2 = makeSprite(0, 200, 100, 100, 0xffff00);

		// connect sprites to handlers
		backend.connectDragSource(sourceId1, source1, {});
		backend.connectDragSource(sourceId2, source2, {});
		backend.connectDropTarget(targetId1, target1, {});
		backend.connectDropTarget(targetId2, target2, {});

		// observe drag source position and update sprite position
		Observable.auto(() -> new Pair(context.getSourceId(), context.getSourcePosition())).bind(null, pair -> {
			var currentSourceId = pair.a;
			var pos = pair.b;
			if (pos != null) {
				if (currentSourceId == sourceId1) {
					source1.parent.x = pos.x;
					source1.parent.y = pos.y;
				}
				if (currentSourceId == sourceId2) {
					source2.parent.x = pos.x;
					source2.parent.y = pos.y;
				}
			}
		});

		// observe drop targets and update sprite opacity
		Observable.auto(() -> context.getTargetIds()).bind(null, targets -> {
			target1.parent.alpha = targets.contains(targetId1) && context.canDropOnTarget(targetId1) ? 0.5 : 1;
			target2.parent.alpha = targets.contains(targetId2) && context.canDropOnTarget(targetId2) ? 0.5 : 1;
		});

		// debug
		Observable.auto(() -> {
			item: context.getItem(),
			sourceId: context.getSourceId(),
			targetIds: context.getTargetIds(),
			position: context.getPosition(),
			sourcePosition: context.getSourcePosition(),
		}).bind(null, v -> trace(v));
	}

	function makeSprite(x, y, w, h, color) {
		final graphic = new Graphics(s2d);
		graphic.beginFill(color);
		graphic.drawRect(0, 0, w, h);
		graphic.x = x;
		graphic.y = y;
		return new Interactive(w, h, graphic);
	}
}

typedef MyItem = {
	final foo:String;
}

typedef MyResult = {
	final bar:String;
}

class MySource implements DragSource<MyItem, MyResult> {
	public function new() {}

	public function beginDrag(ctx:Context<MyItem, MyResult>, sourceId:SourceId):MyItem {
		trace('beginDrag');
		return {foo: 'bar'}
	}

	public function endDrag(ctx:Context<MyItem, MyResult>, sourceId:SourceId):Void {
		trace('endDrag');
	}

	public function canDrag(ctx:Context<MyItem, MyResult>, sourceId:SourceId):Bool {
		trace('canDrag');
		return true;
	}

	public function isDragging(ctx:Context<MyItem, MyResult>, sourceId:SourceId):Bool {
		trace('isDragging');
		return ctx.getItem() != null;
	}
}

class MyTarget implements DropTarget<MyItem, MyResult> {
	public function new() {}

	public function canDrop(ctx:Context<MyItem, MyResult>, targetId:TargetId):Bool {
		trace('canDrop');
		return true;
	}

	public function hover(ctx:Context<MyItem, MyResult>, targetId:TargetId):Void {
		trace('hover');
	}

	public function drop(ctx:Context<MyItem, MyResult>, targetId:TargetId):MyResult {
		trace('drop');

		trace(targetId);
		trace(ctx.getDropResult());
		return {bar: 'foo'};
	}
}
