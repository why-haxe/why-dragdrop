package;

import h2d.Interactive;
import h2d.Graphics;
import why.dragdrop.*;
import why.dragdrop.backend.*;
import tink.state.Observable;

class Heaps extends hxd.App {
	static function main() {
		new Heaps();
	}

	override function init() {
		final manager = new Manager();
		final context = manager.getMonitor();
		final backend = new HeapsBackend(s2d, context, manager.getActions());
		manager.setBackend(backend);

		var sourceId = manager.getRegistry().addSource('DEFAULT', new MySource());
		var targetId = manager.getRegistry().addTarget(['DEFAULT'], new MyTarget());
		var targetId2 = manager.getRegistry().addTarget(['DEFAULT'], new MyTarget());

		var target2 = makeSprite(200, 0, 300, 300, 0x0000ff);
		var target = makeSprite(300, 100, 100, 100, 0x00ff00);
		var source = makeSprite(0, 0, 100, 100, 0xff0000);

		backend.connectDragSource(sourceId, source, {});
		backend.connectDropTarget(targetId, target, {});
		backend.connectDropTarget(targetId2, target2, {});

		Observable.auto(() -> context.getSourceClientOffset()).bind(null, pos -> {
			if (pos != null) {
				source.parent.x = pos.x;
				source.parent.y = pos.y;
			}
		});

		Observable.auto(() -> context.getTargetIds()).bind(null, targets -> {
			target.parent.alpha = targets.contains(targetId) ? 0.5 : 1;
			target2.parent.alpha = targets.contains(targetId2) ? 0.5 : 1;
		});

		Observable.auto(() -> {
			item: context.getItem(),
			sourceId: context.getSourceId(),
			targetIds: context.getTargetIds(),
			clientOffset: context.getClientOffset(),
			sourceClientOffset: context.getSourceClientOffset(),
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

class MySource implements DragSource {
	public function new() {}

	public function beginDrag(ctx:Context, sourceId:SourceId):Any {
		trace('beginDrag');
		return {foo: 'bar'}
	}

	public function endDrag(ctx:Context, sourceId:SourceId):Void {
		trace('endDrag');
	}

	public function canDrag(ctx:Context, sourceId:SourceId):Bool {
		trace('canDrag');
		return true;
	}

	public function isDragging(ctx:Context, sourceId:SourceId):Bool {
		trace('isDragging');
		return ctx.getItem() != null;
	}
}

class MyTarget implements DropTarget {
	public function new() {}

	public function canDrop(ctx:Context, targetId:TargetId):Bool {
		trace('canDrop');
		return true;
	}

	public function hover(ctx:Context, targetId:TargetId):Void {
		trace('hover');
	}

	public function drop(ctx:Context, targetId:TargetId):Any {
		trace('drop');
		return {bar: 'foo'};
	}
}
