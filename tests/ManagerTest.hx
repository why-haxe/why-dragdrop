package;

import Sources;
import Targets;
import why.dragdrop.*;

using tink.CoreApi;

@:asserts
class ManagerTest {
	var manager:Manager;
	var backend:TestBackend;
	var registry:Registry;

	public function new() {}

	@:before
	public function before() {
		backend = new TestBackend();
		manager = new Manager(backend);
		backend.setManager(manager);
		registry = manager.getRegistry();
		return Promise.NOISE;
	}

	@:describe('registers and unregisters drag sources')
	public function registerDragSource() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		asserts.assert(registry.getSource(sourceId) == source, 'getSource');

		registry.removeSource(sourceId);

		Callback.defer(() -> {
			asserts.assert(registry.getSource(sourceId) == null);
			asserts.assert(expectThrow(() -> registry.removeSource(sourceId)));
			asserts.done();
		});

		return asserts;
	}

	@:describe('registers and unregisters drop targets')
	public function registerDropTarget() {
		final target = new NormalTarget();
		final targetId = registry.addTarget([Types.FOO], target);
		asserts.assert(registry.getTarget(targetId) == target, 'getTarget');

		registry.removeTarget(targetId);

		Callback.defer(() -> {
			asserts.assert(registry.getTarget(targetId) == null);
			asserts.assert(expectThrow(() -> registry.removeTarget(targetId)));
			asserts.done();
		});

		return asserts;
	}

	@:describe('registers and unregisters multi-type drop targets')
	public function registerMultiTypeDropTarget() {
		final target = new NormalTarget();
		final targetId = registry.addTarget([Types.FOO, Types.BAR], target);
		asserts.assert(registry.getTarget(targetId) == target, 'getTarget');

		registry.removeTarget(targetId);

		Callback.defer(() -> {
			asserts.assert(registry.getTarget(targetId) == null);
			asserts.assert(expectThrow(() -> registry.removeTarget(targetId)));
			asserts.done();
		});

		return asserts;
	}

	@:describe('calls setup() and teardown() on backend')
	public function callSetupTeardown() {
		Callback.defer(() -> {
			asserts.assert(backend.didCallSetup == false);
			asserts.assert(backend.didCallTeardown == false);

			final sourceId = registry.addSource(Types.FOO, new NormalSource());
			asserts.assert(backend.didCallSetup == true);
			asserts.assert(backend.didCallTeardown == false);
			backend.didCallSetup = false;
			backend.didCallTeardown = false;

			final targetId = registry.addTarget([Types.FOO], new NormalTarget());
			asserts.assert(backend.didCallSetup == false);
			asserts.assert(backend.didCallTeardown == false);
			backend.didCallSetup = false;
			backend.didCallTeardown = false;

			registry.removeSource(sourceId);
			asserts.assert(backend.didCallSetup == false);
			asserts.assert(backend.didCallTeardown == false);
			backend.didCallSetup = false;
			backend.didCallTeardown = false;

			registry.removeTarget(targetId);
			asserts.assert(backend.didCallSetup == false);
			asserts.assert(backend.didCallTeardown == true);
			backend.didCallSetup = false;
			backend.didCallTeardown = false;

			registry.addTarget([Types.BAR], new NormalTarget());
			asserts.assert(backend.didCallSetup == true);
			asserts.assert(backend.didCallTeardown == false);

			asserts.done();
		});
		return asserts;
	}

	// describe('drag source and target contract', () -> {
	// describe('beginDrag() and canDrag()', () -> {

	@:describe('ignores beginDrag() if canDrag() returns false')
	public function ignoreBeginDrag() {
		final source = new NonDraggableSource();
		final sourceId = registry.addSource(Types.FOO, source);

		backend.simulateBeginDrag([sourceId], {});
		asserts.assert(source.didCallBeginDrag == false);

		return asserts.done();
	}

	// @:describe('throws if beginDrag() returns non-object')
	// public function throwBeginDrag() {
	// 	final source = new BadItemSource();
	// 	final sourceId = registry.addSource(Types.FOO, source);
	// 	asserts.assert(expectThrow(() -> backend.simulateBeginDrag([sourceId], {})));
	// 	return asserts.done();
	// }

	@:describe('begins drag if canDrag() returns true')
	public function beginDrag() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		backend.simulateBeginDrag([sourceId], {});
		asserts.assert(source.didCallBeginDrag == true);
		return asserts.done();
	}

	@:describe('throws in beginDrag() if it is called twice during one operation')
	public function throwBeginDrag2() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		backend.simulateBeginDrag([sourceId], {});
		asserts.assert(expectThrow(() -> backend.simulateBeginDrag([sourceId], {})));
		return asserts.done();
	}

	// @:describe('throws in beginDrag() if it is called with an invalid handles')
	// public function throwBeginDrag3() {
	// 	final source = new NormalSource();
	// 	final sourceId = registry.addSource(Types.FOO, source);
	// 	final target = new NormalTarget();
	// 	final targetId = registry.addTarget([Types.FOO], target);
	// 	asserts.assert(expectThrow(() -> backend.simulateBeginDrag('yo')));
	// 	asserts.assert(expectThrow(() -> backend.simulateBeginDrag(null)));
	// 	asserts.assert(expectThrow(() -> backend.simulateBeginDrag(sourceId)));
	// 	asserts.assert(expectThrow(() -> backend.simulateBeginDrag([null])));
	// 	asserts.assert(expectThrow(() -> backend.simulateBeginDrag(['yo'])));
	// 	asserts.assert(expectThrow(() -> backend.simulateBeginDrag([targetId])));
	// 	asserts.assert(() -> backend.simulateBeginDrag([null, sourceId]))
	// 		.toThrow() asserts.assert(expectThrow(() -> backend.simulateBeginDrag([targetId, sourceId])));
	// 	registry.removeSource(sourceId) setImmediate(() -> {
	// 		asserts.assert(expectThrow(() -> backend.simulateBeginDrag([sourceId])));
	// 		done()
	// 	})
	// }

	@:describe('calls beginDrag() on the innermost handler with canDrag() returning true')
	public function callInnermostBeginDrag() {
		final sourceA = new NonDraggableSource();
		final sourceAId = registry.addSource(Types.FOO, sourceA);
		final sourceB = new NormalSource();
		final sourceBId = registry.addSource(Types.FOO, sourceB);
		final sourceC = new NormalSource();
		final sourceCId = registry.addSource(Types.FOO, sourceC);
		final sourceD = new NonDraggableSource();
		final sourceDId = registry.addSource(Types.FOO, sourceD);
		backend.simulateBeginDrag([sourceAId, sourceBId, sourceCId, sourceDId], {});
		asserts.assert(sourceA.didCallBeginDrag == false);
		asserts.assert(sourceB.didCallBeginDrag == false);
		asserts.assert(sourceC.didCallBeginDrag == true);
		asserts.assert(sourceD.didCallBeginDrag == false);
		return asserts.done();
	}

	@:describe('lets beginDrag() be called again in a next operation')
	public function beginDragAgain() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateEndDrag();
		source.didCallBeginDrag = false;
		asserts.assert(!expectThrow(() -> backend.simulateBeginDrag([sourceId], {})));
		asserts.assert(source.didCallBeginDrag == true);
		return asserts.done();
	}

	function expectThrow(f:() -> Void) {
		return try {
			f();
			false;
		} catch (e) {
			// trace(e);
			true;
		}
	}
}
