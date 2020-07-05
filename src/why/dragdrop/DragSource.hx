package why.dragdrop;

private typedef Item = Any;

interface DragSource {
	function beginDrag(ctx:Context, sourceId:SourceId):Item;
	function endDrag(ctx:Context, sourceId:SourceId):Void;
	function canDrag(ctx:Context, sourceId:SourceId):Bool;
	function isDragging(ctx:Context, sourceId:SourceId):Bool;
}
