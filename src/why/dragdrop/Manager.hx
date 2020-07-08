package why.dragdrop;

import why.dragdrop.BeginDragPayload;
import haxe.Exception;
import tink.Anon.splat;
import tink.state.Observable;
import tink.state.State;

enum Event {
	BeginDrag(beginDrag:BeginDragPayload);
	PublishDragSource;
	Hover(hover:HoverPayload);
	Drop(drop:DropPayload);
	EndDrag;
}

class Manager<Node> {
	final events:Signal<Event>;
	final context:Context;
	final backend:State<Backend<Node>>;
	final registry:Registry;
	final actions:Actions;

	final eventsTrigger:SignalTrigger<Event>;

	public function new() {
		registry = new Registry();
		context = new Context(registry);
		backend = new State(null);
		actions = new ManagerActions(this);
		events = eventsTrigger = Signal.trigger();

		var registryCount = Observable.auto(() -> Lambda.count(registry.sources) + Lambda.count(registry.targets));
		var backendBinding:CallbackLink = null;
		backend.bind(null, backend -> {
			backendBinding.cancel();
			if (backend != null) {
				var isSetUp = false;
				backendBinding = registryCount.bind({direct: true}, count -> {
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
		});
	}

	public inline function setBackend(value:Backend<Node>) {
		backend.set(value);
	}

	public inline function getMonitor():Context {
		return context;
	}

	public inline function getBackend():Backend<Node> {
		return backend.value;
	}

	public inline function getRegistry():Registry {
		return registry;
	}

	public inline function getActions():Actions {
		return actions;
	}

	public inline function dispatch(event:Event) {
		eventsTrigger.trigger(event);
	}
}

class ManagerActions<Node> implements Actions {
	final manager:Manager<Node>;
	final context:Context;
	final registry:Registry;
	final signal:SignalTrigger<Event>;

	public function new(manager) {
		this.manager = manager;
		this.context = manager.getMonitor();
		this.registry = manager.getRegistry();

		// in the original library the side effects are applied to a redux store
		// our Context does the same thing with Observables
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
				context.__clientOffset.set(hover.clientOffset);

			// TODO: https://github.com/react-dnd/react-dnd/blob/debc89829dd988f4e942a0251eba36c34a070f42/packages/core/dnd-core/src/reducers/dragOperation.ts#L66-L73

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
				context.__isSourcePublic.set(false);
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
		trace(clientOffset);
		if (clientOffset != null) {
			if (getSourceClientOffset == null) {
				throw new Exception('getSourceClientOffset must be defined');
			}
			sourceClientOffset = getSourceClientOffset(sourceId);
		}
		trace(sourceClientOffset);

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

	public function publishDragSource() {
		if (context.isDragging())
			signal.trigger(PublishDragSource);
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

		signal.trigger(Hover({
			targetIds: targetIds,
			clientOffset: options.clientOffset,
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
				dropResult = index == 0 ? {} : context.getDropResult();

			signal.trigger(Drop({dropResult: dropResult}));
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
		signal.trigger(EndDrag);
	}
}
