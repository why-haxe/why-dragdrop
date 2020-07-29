package why.dragdrop;

typedef BeginDragOptions = {
	final ?publishSource:Bool;
	final ?clientOffset:Point;
	final ?getSourceClientOffset:(sourceId:SourceId) -> Point;
}
