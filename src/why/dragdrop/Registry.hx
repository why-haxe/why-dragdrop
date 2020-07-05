package why.dragdrop;

import haxe.Exception;
import tink.core.Callback;
import tink.state.ObservableMap;

@:allow(why.dragdrop)
class Registry {
	final sourceTypes:Map<SourceId, SourceType> = new Map();
	final targetTypes:Map<TargetId, Array<TargetType>> = new Map();
	final sources:ObservableMap<SourceId, DragSource> = new ObservableMap([]);
	final targets:ObservableMap<TargetId, DropTarget> = new ObservableMap([]);

	var pinnedSourceId:SourceId;
	var pinnedSource:DragSource;

	public function new() {}

	public function addSource(type:SourceType, source:DragSource):SourceId {
		final id = new SourceId();
		sourceTypes.set(id, type);
		sources.set(id, source);
		return id;
	}

	public function addTarget(type:Array<TargetType>, target:DropTarget):TargetId {
		final id = new TargetId();
		targetTypes.set(id, type);
		targets.set(id, target);
		return id;
	}

	public function containsSource(handler:DragSource):Bool {
		for (source in sources)
			if (source == handler)
				return true;
		return false;
	}

	public function containsTarget(handler:DropTarget):Bool {
		for (target in targets)
			if (target == handler)
				return true;
		return false;
	}

	public function getSource(sourceId:SourceId, includePinned:Bool = false):DragSource {
		final isPinned = includePinned && sourceId == pinnedSourceId;
		return isPinned ? pinnedSource : sources.get(sourceId);
	}

	public function getTarget(targetId:TargetId):DropTarget {
		return targets.get(targetId);
	}

	public function getSourceType(sourceId:SourceId):SourceType {
		return sourceTypes.get(sourceId);
	}

	public function getTargetType(targetId:TargetId):Array<TargetType> {
		return targetTypes.get(targetId);
	}

	public function hasSource(sourceId:SourceId):Bool {
		return sources.exists(sourceId);
	}

	public function hasTarget(targetId:TargetId):Bool {
		return targets.exists(targetId);
	}

	public function removeSource(sourceId:SourceId):Void {
		if (this.getSource(sourceId) == null)
			throw new Exception('Expected an existing source.');
		// TODO: signal

		// TODO: asap
		// Callback.defer(() -> {
		sources.remove(sourceId);
		sourceTypes.remove(sourceId);
		// });
	}

	public function removeTarget(targetId:TargetId):Void {
		if (this.getTarget(targetId) == null)
			throw new Exception('Expected an existing target.');
		// TODO: signal
		targets.remove(targetId);
		targetTypes.remove(targetId);
	}

	public function pinSource(sourceId:SourceId):Void {
		switch getSource(sourceId) {
			case null:
			case source:
				pinnedSourceId = sourceId;
				pinnedSource = source;
		}
	}

	public function unpinSource():Void {
		pinnedSourceId = null;
		pinnedSource = null;
	}
}
