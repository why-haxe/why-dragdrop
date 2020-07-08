package why.dragdrop;

typedef BeginDragPayload<Item> = {
	itemType:SourceType,
	item:Item,
	sourceId:SourceId,
	clientOffset:Point,
	sourceClientOffset:Point,
	isSourcePublic:Bool,
}
