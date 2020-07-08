package why.dragdrop;

interface DragSource<Item> {
	function beginDrag(ctx:Context<Item>, sourceId:SourceId):Item;
	function endDrag(ctx:Context<Item>, sourceId:SourceId):Void;
	function canDrag(ctx:Context<Item>, sourceId:SourceId):Bool;
	function isDragging(ctx:Context<Item>, sourceId:SourceId):Bool;
}
