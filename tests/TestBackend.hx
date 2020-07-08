package;

import why.dragdrop.*;

using tink.CoreApi;

typedef Node = Any; // TODO: make it a type parameter

class TestBackend implements Backend<Noise> {
	public var didCallSetup:Bool = false;
	public var didCallTeardown:Bool = false;

	var manager:Manager<Noise>;
	var actions:;

	public function new(manager) {
		this.manager = manager;
		this.actions = manager.getActions();
	}

	public function profile():Map<String, Int> {
		return new Map();
	}

	public function setup():Void {
		this.didCallSetup = true;
	}

	public function teardown():Void {
		this.didCallTeardown = true;
	}

	public function connectDragSource(sourceId:SourceId, ?node:Noise, options:Any):CallbackLink {
		return null;
	}

	public function connectDragPreview(sourceId:SourceId, ?node:Noise, options:Any):CallbackLink {
		return null;
	}

	public function connectDropTarget(targetId:SourceId, ?node:Noise, options:Any):CallbackLink {
		return null;
	}

	public function simulateBeginDrag(sourceIds:Array<SourceId>, options:BeginDragOptions):Void {
		actions.beginDrag(sourceIds, options);
	}

	public function simulatePublishDragSource():Void {
		actions.publishDragSource();
	}

	public function simulateHover(targetIds:Array<TargetId>, options:HoverOptions):Void {
		actions.hover(targetIds, options);
	}

	public function simulateDrop():Void {
		actions.drop({});
	}

	public function simulateEndDrag():Void {
		actions.endDrag();
	}
}

// interface ITestBackend extends Backend {
// 	var didCallSetup:Bool;
// 	var didCallTeardown:Bool;
// 	function simulateBeginDrag(sourceIds:Array<SourceId>, ?options:Any):Void;
// 	function simulatePublishDragSource():Void;
// 	function simulateHover(targetIds:Array<TargetId>, ?options:Any):Void;
// 	function simulateDrop():Void;
// 	function simulateEndDrag():Void;
// }
