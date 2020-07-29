package why.dragdrop;

typedef BeginDragPayload<Item> = {
	final itemType:SourceType;
	final item:Item;
	final sourceId:SourceId;
	final clientOffset:Point;
	final sourceClientOffset:Point;
	final isSourcePublic:Bool;
}
