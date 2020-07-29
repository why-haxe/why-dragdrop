package why.dragdrop;

typedef BeginDragOptions = {
	final ?publishSource:Bool;
	final ?position:Point;
	final ?getSourcePosition:(sourceId:SourceId) -> Point;
}
