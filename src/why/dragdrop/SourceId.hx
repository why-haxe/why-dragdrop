package why.dragdrop;

abstract SourceId(Int) {
	static var counter = 0;
	public inline function new() this = counter++;
}