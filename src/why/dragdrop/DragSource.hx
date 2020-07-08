package why.dragdrop;

interface DragSource<Item, Result> {
	function beginDrag(ctx:Context<Item, Result>, sourceId:SourceId):Item;
	function endDrag(ctx:Context<Item, Result>, sourceId:SourceId):Void;
	function canDrag(ctx:Context<Item, Result>, sourceId:SourceId):Bool;
	function isDragging(ctx:Context<Item, Result>, sourceId:SourceId):Bool;
}
