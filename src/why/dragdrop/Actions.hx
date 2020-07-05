package why.dragdrop;

interface Actions<Event> {
	function beginDrag(sourceIds:Array<SourceId>, options:BeginDragOptions):Void;
	function publishDragSource():Void;
	function hover(targetIds:Array<TargetId>, options:HoverOptions):Void;
	function drop(options:Any):Void;
	function endDrag():Void;
}
