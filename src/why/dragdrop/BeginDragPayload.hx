package why.dragdrop;

typedef BeginDragPayload<Item> = {
	final itemType:SourceType;
	final item:Item;
	final sourceId:SourceId;
	final position:Point;
	final sourcePosition:Point;
	final isSourcePublic:Bool;
}
