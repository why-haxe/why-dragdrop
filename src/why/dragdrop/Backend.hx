package why.dragdrop;

using tink.CoreApi;

typedef Node = Any; // TODO: make it a type parameter

interface Backend {
	function setup():Void;
	function teardown():Void;
	function connectDragSource(sourceId:SourceId, ?node:Node, options:Any):CallbackLink;
	function connectDragPreview(sourceId:SourceId, ?node:Node, options:Any):CallbackLink;
	function connectDropTarget(targetId:SourceId, ?node:Node, options:Any):CallbackLink;
	function profile():Map<String, Int>;
}

