package why.dragdrop;

abstract TargetId(Null<Int>) {
	static var counter = 0;
	public inline function new() this = counter++;
}