package why.dragdrop;

interface DropTarget<Item> {
	function canDrop(ctx:Context<Item>, targetId:TargetId):Bool;
	function hover(ctx:Context<Item>, targetId:TargetId):Void;
	function drop(ctx:Context<Item>, targetId:TargetId):Any;
}