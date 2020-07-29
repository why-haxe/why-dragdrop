package why.dragdrop;

import why.dragdrop.BeginDragPayload;
import haxe.Exception;
import tink.Anon.splat;
import tink.state.Observable;
import tink.state.State;

enum Event<Item, Result> {
	BeginDrag(beginDrag:BeginDragPayload<Item>);
	PublishDragSource;
	Hover(hover:HoverPayload);
	Drop(drop:DropPayload<Result>);
	EndDrag;
}

class Manager<Item, Result, Node> {
	public final registry:Registry<Item, Result>;
	public final context:Context<Item, Result>;
	public final actions:Actions;
	public final backend:Backend<Node>;

	public function new(makeBackend:Manager<Item, Result, Node>->Backend<Node>) {
		registry = new Registry();
		context = new Context(registry);
		actions = new ManagerActions(this);
		backend = makeBackend(this);

		var registryCount = Observable.auto(() -> Lambda.count(registry.sources) + Lambda.count(registry.targets));
		var isSetUp = false;

		registryCount.bind({direct: true}, count -> {
			final shouldSetUp = count > 0;
			if (shouldSetUp && !isSetUp) {
				backend.setup();
				isSetUp = true;
			} else if (!shouldSetUp && isSetUp) {
				backend.teardown();
				isSetUp = false;
			}
		});
	}

	// @:deprecated public inline function getMonitor():Context<Item, Result> {
	// 	return context;
	// }
	// @:deprecated public inline function getBackend():Backend<Node> {
	// 	return backend;
	// }
	// @:deprecated public inline function getRegistry():Registry<Item, Result> {
	// 	return registry;
	// }
	// @:deprecated public inline function getActions():Actions {
	// 	return actions;
	// }
}

class ManagerActions<Item, Result, Node> implements Actions {
	final context:Context<Item, Result>;
	final registry:Registry<Item, Result>;

	public function new(manager:Manager<Item, Result, Node>) {
		this.context = manager.context;
		this.registry = manager.registry;
	}

	function trigger(event:Event<Item, Result>)
		switch event {
			case BeginDrag(beginDrag):
				context.__itemType.set(beginDrag.itemType);
				context.__item.set(beginDrag.item);
				context.__sourceId.set(beginDrag.sourceId);
				context.__position.set(beginDrag.position);
				context.__initialPosition.set(beginDrag.position);
				context.__initialSourcePosition.set(beginDrag.sourcePosition);
				context.__isSourcePublic.set(beginDrag.isSourcePublic);
			case PublishDragSource:
				context.__isSourcePublic.set(true);
			case Hover(hover):
				context.__targetIds.set(hover.targetIds);
				context.__position.set(hover.position);
			// TODO: https://github.com/react-dnd/react-dnd/blob/debc89829dd988f4e942a0251eba36c34a070f42/packages/core/dnd-core/src/reducers/dragOperation.ts#L66-L73
			case Drop(drop):
				context.__dropResult.set(drop.dropResult);
				context.__didDrop.set(true);
				context.__targetIds.set([]);
				context.__position.set(null);
				context.__initialPosition.set(null);
				context.__initialSourcePosition.set(null);
			case EndDrag:
				context.__itemType.set(null);
				context.__item.set(null);
				context.__sourceId.set(null);
				context.__dropResult.set(null);
				context.__didDrop.set(false);
				context.__isSourcePublic.set(false);
				context.__targetIds.set([]);
				context.__position.set(null);
				context.__initialPosition.set(null);
				context.__initialSourcePosition.set(null);
		}

	public function beginDrag(sourceIds:Array<SourceId>, options:BeginDragOptions) {
		splat(options);

		// Initialize the coordinates using the client offset
		// context.setInitialPosition(position);

		if (context.isDragging())
			throw new Exception('Cannot call beginDrag while dragging.');

		for (sourceId in sourceIds)
			if (!registry.hasSource(sourceId))
				throw new Exception('Expected sourceIds to be registered.');

		final sourceId = context.getDraggableSource(sourceIds);
		if (sourceId == null) {
			// context.setInitialPosition(null);
			// context.setInitialSourcePosition(null);
			return;
		}

		// Get the source client offset
		var sourcePosition = null;
		if (position != null) {
			if (getSourcePosition == null) {
				throw new Exception('getSourcePosition must be defined');
			}
			sourcePosition = getSourcePosition(sourceId);
		}

		// Initialize the full coordinates
		// context.setInitialPosition(position);
		// context.setInitialSourcePosition(sourcePosition);
		final source = registry.getSource(sourceId);
		final item = source.beginDrag(context, sourceId);

		registry.pinSource(sourceId);
		final itemType = registry.getSourceType(sourceId);

		trigger(BeginDrag({
			itemType: itemType,
			item: item,
			sourceId: sourceId,
			position: position,
			sourcePosition: sourcePosition,
			isSourcePublic: publishSource == true,
		}));
	}

	public function publishDragSource() {
		if (context.isDragging())
			trigger(PublishDragSource);
	}

	public function hover(targetIds:Array<TargetId>, options:HoverOptions):Void {
		final targetIds = targetIds.copy();
		final draggedItemType = context.getItemType();

		// checkInvariants
		if (!context.isDragging())
			throw new Exception('Cannot call hover while not dragging.');
		if (context.didDrop())
			throw new Exception('Cannot call hover after drop.');
		for (i => targetId in targetIds) {
			if (targetIds.lastIndexOf(targetId) != i)
				throw new Exception('Expected targetIds to be unique in the passed array.');

			final target = registry.getTarget(targetId);
			if (target == null)
				throw new Exception('Expected targetIds to be registered.');
		}

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

		trigger(Hover({
			targetIds: targetIds,
			position: options.position,
		}));
	}

	public function drop(options:Any) {
		if (!context.isDragging())
			throw new Exception('Cannot call drop while not dragging.');
		if (context.didDrop())
			throw new Exception('Cannot call drop twice during one drag operation.');

		final targetIds = context.getDroppableTargets();

		for (index => targetId in targetIds) {
			final target = registry.getTarget(targetId);
			var dropResult = target != null ? target.drop(context, targetId) : null;
			if (dropResult == null)
				dropResult = index == 0 ? cast {} : context.getDropResult(); // TODO: fix cast

			trigger(Drop({dropResult: dropResult}));
		}
	}

	public function endDrag() {
		if (!context.isDragging())
			throw new Exception('Cannot call endDrag while not dragging.');
		final sourceId = context.getSourceId();
		if (sourceId != null) {
			final source = registry.getSource(sourceId, true);
			source.endDrag(context, sourceId);
			registry.unpinSource();
		}
		trigger(EndDrag);
	}
}
