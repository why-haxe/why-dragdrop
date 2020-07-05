package why.dragdrop;

import why.dragdrop.BeginDragPayload;
import haxe.Exception;
import tink.Anon.splat;
import tink.state.Observable;

enum Event {
	BeginDrag(beginDrag:BeginDragPayload);
	PublishDragSource;
	Hover(hover:HoverPayload);
	Drop(drop:DropPayload);
	EndDrag;
}

class Manager {
	public final events:Signal<Event>;
	public final context:Context;
	public final backend:Backend;
	public final registry:Registry;
	public final actions:Actions<Event>;

	final eventsTrigger:SignalTrigger<Event>;

	var isSetUp = false;

	public function new(backend) {
		registry = new Registry();
		context = new Context(registry);
		this.backend = backend;
		actions = new ManagerActions(this);
		events = eventsTrigger = Signal.trigger();

		Observable.auto(() -> Lambda.count(registry.sources) + Lambda.count(registry.targets)).bind({direct: true}, count -> {
			final shouldSetUp = count > 0;
			if (backend != null) {
				if (shouldSetUp && !this.isSetUp) {
					backend.setup();
					isSetUp = true;
				} else if (!shouldSetUp && this.isSetUp) {
					backend.teardown();
					isSetUp = false;
				}
			}
		});
	}

	public inline function getMonitor():Context {
		return context;
	}

	public inline function getBackend():Backend {
		return backend;
	}

	public inline function getRegistry():Registry {
		return registry;
	}

	public inline function getActions():Actions<Event> {
		return actions;
	}

	public inline function dispatch(event:Event) {
		eventsTrigger.trigger(event);
	}
}

class ManagerActions implements Actions<Event> {
	final manager:Manager;
	final context:Context;
	final registry:Registry;
	final signal:SignalTrigger<Event>;

	public function new(manager:Manager) {
		this.manager = manager;
		this.context = manager.getMonitor();
		this.registry = manager.getRegistry();

		signal = Signal.trigger();
		signal.asSignal().handle(function(event) switch event {
			case BeginDrag(beginDrag):
				context.__itemType.set(beginDrag.itemType);
				context.__item.set(beginDrag.item);
				context.__sourceId.set(beginDrag.sourceId);
				context.__clientOffset.set(beginDrag.clientOffset);
				context.__initialClientOffset.set(beginDrag.clientOffset);
				context.__initialSourceClientOffset.set(beginDrag.sourceClientOffset);
				context.__isSourcePublic.set(beginDrag.isSourcePublic);
			case PublishDragSource:
				context.__isSourcePublic.set(true);

			case Hover(hover):
				context.__targetIds.set(hover.targetIds);

			case Drop(drop):
				context.__dropResult.set(drop.dropResult);
				context.__didDrop.set(true);
				context.__targetIds.set([]);

			case EndDrag:
				context.__itemType.set(null);
				context.__item.set(null);
				context.__sourceId.set(null);
				context.__dropResult.set(null);
				context.__didDrop.set(false);
				context.__isSourcePublic.set(null);
				context.__targetIds.set([]);
		});
	}

	public function beginDrag(sourceIds:Array<SourceId>, options:BeginDragOptions) {
		splat(options);

		// Initialize the coordinates using the client offset
		// context.setInitialClientOffset(clientOffset);

		if (context.isDragging())
			throw new Exception('Cannot call beginDrag while dragging.');

		for (sourceId in sourceIds)
			if (!registry.hasSource(sourceId))
				throw new Exception('Expected sourceIds to be registered.');

		final sourceId = context.getDraggableSource(sourceIds);
		if (sourceId == null) {
			// context.setInitialClientOffset(null);
			// context.setInitialSourceClientOffset(null);
			return;
		}

		// Get the source client offset
		var sourceClientOffset = null;
		if (clientOffset != null) {
			if (getSourceClientOffset == null) {
				throw new Exception('getSourceClientOffset must be defined');
			}
			sourceClientOffset = getSourceClientOffset(sourceId);
		}

		// Initialize the full coordinates
		// context.setInitialClientOffset(clientOffset);
		// context.setInitialSourceClientOffset(sourceClientOffset);
		final source = registry.getSource(sourceId);
		final item = source.beginDrag(context, sourceId);

		registry.pinSource(sourceId);
		final itemType = registry.getSourceType(sourceId);

		signal.trigger(BeginDrag({
			itemType: itemType,
			item: item,
			sourceId: sourceId,
			clientOffset: clientOffset,
			sourceClientOffset: sourceClientOffset,
			isSourcePublic: publishSource == true,
		}));
	}

	public function publishDragSource():Option<Event> {
		return if (context.isDragging()) Some(PublishDragSource) else None;
	}

	public function hover(targetIds:Array<TargetId>, options:HoverOptions):Event {
		var targetIds = targetIds.copy();
		var draggedItemType = context.getItemType();

		// removeNonMatchingTargetIds
		var i = targetIds.length - 1;
		while (i >= 0) {
			final targetId = targetIds[i];
			final targetType = registry.getTargetType(targetId);
			if (!targetType.contains(draggedItemType))
				targetIds.splice(i, 1);
			i--;
		}

		// hoverAllTargets
		for (targetId in targetIds) {
			final target = registry.getTarget(targetId);
			target.hover(context, targetId);
		}

		return Hover({
			targetIds: targetIds,
			clientOffset: options.clientOffset,
		});
	}

	public function drop(options:Any):Array<Event> {
		final targetIds = context.getDroppableTargets();
		return [
			for (index => targetId in targetIds) {
				final dropResult = (function determineDropResult() {
					final target = registry.getTarget(targetId);
					var dropResult = target != null ? target.drop(context, targetId) : null;
					if (dropResult == null)
						dropResult = index == 0 ? {} : context.getDropResult();
					return dropResult;
				})();
				Drop({dropResult: dropResult});
			}
		];
	}

	public function endDrag() {
		if (!context.isDragging())
			throw new Exception('Cannot call endDrag while not dragging.');
		var sourceId = context.getSourceId();
		if (sourceId != null) {
			final source = registry.getSource(sourceId, true);
			source.endDrag(context, sourceId);
			registry.unpinSource();
		}
		signal.trigger(EndDrag);
	}
}