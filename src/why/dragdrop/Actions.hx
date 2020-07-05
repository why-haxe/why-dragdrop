package why.dragdrop;

interface Actions<Event> {
	function beginDrag(sourceIds:Array<SourceId>, options:BeginDragOptions):Void;
	function publishDragSource():Option<Event>;
	function hover(targetIds:Array<TargetId>, options:HoverOptions):Event;
	function drop(options:Any):Array<Event>;
	function endDrag():Void;
}
