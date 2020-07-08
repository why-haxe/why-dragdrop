package why.dragdrop;

interface DropTarget<Item, Result> {
	function canDrop(ctx:Context<Item, Result>, targetId:TargetId):Bool;
	function hover(ctx:Context<Item, Result>, targetId:TargetId):Void;
	function drop(ctx:Context<Item, Result>, targetId:TargetId):Result;
}
