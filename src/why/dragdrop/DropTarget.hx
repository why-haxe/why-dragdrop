package why.dragdrop;

interface DropTarget {
	function canDrop(ctx:Context, targetId:TargetId):Bool;
	function hover(ctx:Context, targetId:TargetId):Void;
	function drop(ctx:Context, targetId:TargetId):Any;
}