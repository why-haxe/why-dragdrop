package why.dragdrop;

typedef Item = Any; // TODO: type param

typedef BeginDragPayload = {
	itemType:SourceType,
	item:Item,
	sourceId:SourceId,
	clientOffset:Point,
	sourceClientOffset:Point,
	isSourcePublic:Bool,
}
