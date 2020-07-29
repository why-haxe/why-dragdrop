package;

@:pure
@:forward(indexOf, iterator, keyValueIterator, join, lastIndexOf, contains, toString)
abstract ImmutableArray<T>(Array<T>) {
	inline function new(v)
		this = v;

	@:from
	public static macro function fromExpr(e:haxe.macro.Expr) {
		return switch e.expr {
			case EArrayDecl(_): macro @:privateAccess new ImmutableArray($e);
			case _: macro @:privateAccess new ImmutableArray($e.copy());
		}
	}

	public var length(get, never):Int;

	inline function get_length()
		return this.length;

	@:arrayAccess inline function get(i:Int)
		return this[i];

	public inline function filter(f:T->Bool):ImmutableArray<T>
		return new ImmutableArray(this.filter(f));

	public inline function map<S>(f:T->S):ImmutableArray<S>
		return new ImmutableArray(this.map(f));

	public inline function slice(pos:Int, ?end:Int):ImmutableArray<T>
		return new ImmutableArray(this.slice(pos, end));

	public inline function reverse():ImmutableArray<T> {
		var copy = this.copy();
		copy.reverse();
		return new ImmutableArray(copy);
	}
}
