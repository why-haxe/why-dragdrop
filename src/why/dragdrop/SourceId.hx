package why.dragdrop;

abstract SourceId(Null<Int>) {
	static var counter = 0;
	public inline function new() this = counter++;
}