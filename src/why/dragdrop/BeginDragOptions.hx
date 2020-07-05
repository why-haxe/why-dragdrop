package why.dragdrop;

typedef BeginDragOptions = {
	?publishSource:Bool,
	?clientOffset:Point,
	?getSourceClientOffset:(sourceId:SourceId) -> Point,
}
