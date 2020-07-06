package why.dragdrop;

using tink.CoreApi;

interface Backend<Node> {
	function setup():Void;
	function teardown():Void;
	function connectDragSource(sourceId:SourceId, ?node:Node, options:Any):CallbackLink;
	function connectDragPreview(sourceId:SourceId, ?node:Node, options:Any):CallbackLink;
	function connectDropTarget(targetId:SourceId, ?node:Node, options:Any):CallbackLink;
	function profile():Map<String, Int>;
}
