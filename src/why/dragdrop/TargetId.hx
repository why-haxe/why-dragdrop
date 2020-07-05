package why.dragdrop;

abstract TargetId(Int) {
	static var counter = 0;
	public inline function new() this = counter++;
}