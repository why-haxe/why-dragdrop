package;

import Sources;
import Targets;
import why.dragdrop.*;

using tink.CoreApi;

@:asserts
class ManagerTest {
	var manager:Manager<Any, Noise>;
	var backend:TestBackend;
	var registry:Registry<Any>;

	public function new() {}

	@:before
	public function before() {
		manager = new Manager();
		backend = new TestBackend(manager);
		manager.setBackend(backend);
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

	// describe('drop(), canDrop() and endDrag()', () -> {

	@:describe('endDrag() sees drop() return value as drop result if dropped on a target')
	public function endDragResult() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final target = new NormalTarget();
		final targetId = registry.addTarget([Types.FOO], target);

		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetId], {});
		backend.simulateDrop();
		backend.simulateEndDrag();
		asserts.assert(target.didCallDrop == true);
		asserts.compare({foo: 'bar'}, source.recordedDropResult);
		return asserts.done();
	}

	@:describe('endDrag() sees {} as drop result by default if dropped on a target')
	public function endDragResultDefault() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final target = new TargetWithNoDropResult();
		final targetId = registry.addTarget([Types.FOO], target);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetId], {});
		backend.simulateDrop();
		backend.simulateEndDrag();
		asserts.compare({}, source.recordedDropResult);
		return asserts.done();
	}

	@:describe('endDrag() sees null as drop result if dropped outside a target')
	public function endDragOutsideTarget() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateEndDrag();
		asserts.assert(source.recordedDropResult == null);
		return asserts.done();
	}

	@:describe('calls endDrag even if source was unregistered')
	public function endDragUnregisteredSource() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		backend.simulateBeginDrag([sourceId], {});
		registry.removeSource(sourceId);
		backend.simulateEndDrag();
		asserts.assert(source.recordedDropResult == null);
		return asserts.done();
	}

	@:describe('throws in endDrag() if it is called outside a drag operation')
	public function throwEndDrag() {
		final source = new NormalSource();
		registry.addSource(Types.FOO, source);
		asserts.assert(expectThrow(() -> backend.simulateEndDrag()));
		return asserts.done();
	}

	@:describe('ignores drop() if no drop targets entered')
	public function ignoreDrop() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateDrop();
		backend.simulateEndDrag();
		asserts.assert(source.recordedDropResult == null);
		return asserts.done();
	}

	@:describe('ignores drop() if drop targets entered and left')
	public function ignoreDrop2() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final targetA = new NormalTarget();
		final targetAId = registry.addTarget([Types.FOO], targetA);
		final targetB = new NormalTarget();
		final targetBId = registry.addTarget([Types.FOO], targetB);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetAId], {});
		backend.simulateHover([targetAId, targetBId], {});
		backend.simulateHover([targetAId], {});
		backend.simulateHover([], {});
		backend.simulateDrop();
		backend.simulateEndDrag();
		asserts.assert(targetA.didCallDrop == false);
		asserts.assert(targetB.didCallDrop == false);
		asserts.assert(source.recordedDropResult == null);
		return asserts.done();
	}

	@:describe('ignores drop() if canDrop() returns false')
	public function ignoreDrop3() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final target = new NonDroppableTarget();
		final targetId = registry.addTarget([Types.FOO], target);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetId], {});
		backend.simulateDrop();
		asserts.assert(target.didCallDrop == false);
		return asserts.done();
	}

	@:describe('ignores drop() if target has a different type')
	public function ignoreDrop4() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final target = new NormalTarget();
		final targetId = registry.addTarget([Types.BAR], target);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetId], {});
		backend.simulateDrop();
		asserts.assert(target.didCallDrop == false);
		return asserts.done();
	}

	@:describe('throws in drop() if it is called outside a drag operation')
	public function throwDrop() {
		asserts.assert(expectThrow(() -> backend.simulateDrop()));
		return asserts.done();
	}

	// @:describe('throws in drop() if it returns something that is neither undefined nor an object')
	// public function throwDrop2() {
	// 	final source = new NormalSource();
	// 	final sourceId = registry.addSource(Types.FOO, source);
	// 	final target = new BadResultTarget();
	// 	final targetId = registry.addTarget([Types.FOO], target);
	// 	backend.simulateBeginDrag([sourceId], {});
	// 	backend.simulateHover([targetId], {});
	// 	asserts.assert(expectThrow(() -> backend.simulateDrop()));
	// 	return asserts.done();
	// }

	@:describe('throws in drop() if called twice')
	public function throwDrop3() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final target = new NormalTarget();
		final targetId = registry.addTarget([Types.FOO], target);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetId], {});
		backend.simulateDrop();
		asserts.assert(expectThrow(() -> backend.simulateDrop()));
		return asserts.done();
	}

	// // describe('nested drop targets', () -> {

	@:describe('uses child result if parents have no drop result')
	public function childResult() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final targetA = new TargetWithNoDropResult();
		final targetAId = registry.addTarget([Types.FOO], targetA);
		final targetB = new NormalTarget({number: 16});
		final targetBId = registry.addTarget([Types.FOO], targetB);
		final targetC = new NormalTarget({number: 42});
		final targetCId = registry.addTarget([Types.FOO], targetC);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetAId, targetBId, targetCId], {});
		backend.simulateDrop();
		backend.simulateEndDrag();
		asserts.assert(targetA.didCallDrop == true);
		asserts.assert(targetB.didCallDrop == true);
		asserts.assert(targetC.didCallDrop == true);
		asserts.compare({number: 16}, source.recordedDropResult);
		return asserts.done();
	}

	@:describe('excludes targets of different type when dispatching drop')
	public function excludeTargetsOfDifferentType() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final targetA = new TargetWithNoDropResult();
		final targetAId = registry.addTarget([Types.FOO], targetA);
		final targetB = new NormalTarget({number: 16});
		final targetBId = registry.addTarget([Types.BAR], targetB);
		final targetC = new NormalTarget({number: 42});
		final targetCId = registry.addTarget([Types.FOO], targetC);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetAId, targetBId, targetCId], {});
		backend.simulateDrop();
		backend.simulateEndDrag();
		asserts.assert(targetA.didCallDrop == true);
		asserts.assert(targetB.didCallDrop == false);
		asserts.assert(targetC.didCallDrop == true);
		asserts.compare({number: 42}, source.recordedDropResult);
		return asserts.done();
	}

	@:describe('excludes non-droppable targets when dispatching drop')
	public function excludeNonDroppableTargets() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final targetA = new TargetWithNoDropResult();
		final targetAId = registry.addTarget([Types.FOO], targetA);
		final targetB = new TargetWithNoDropResult();
		final targetBId = registry.addTarget([Types.FOO], targetB);
		final targetC = new NonDroppableTarget();
		final targetCId = registry.addTarget([Types.BAR], targetC);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetAId, targetBId, targetCId], {});
		backend.simulateDrop();
		backend.simulateEndDrag();
		asserts.assert(targetA.didCallDrop == true);
		asserts.assert(targetB.didCallDrop == true);
		asserts.assert(targetC.didCallDrop == false);
		asserts.compare({}, source.recordedDropResult);
		return asserts.done();
	}

	@:describe('lets parent drop targets transform child results')
	public function parentTransformChild() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final targetA = new TargetWithNoDropResult();
		final targetAId = registry.addTarget([Types.FOO], targetA);
		final targetB = new TransformResultTarget(dropResult -> {number: (cast dropResult).number * 2});
		final targetBId = registry.addTarget([Types.FOO], targetB);
		final targetC = new NonDroppableTarget();
		final targetCId = registry.addTarget([Types.FOO], targetC);
		final targetD = new TransformResultTarget(dropResult -> {number: (cast dropResult).number + 1});
		final targetDId = registry.addTarget([Types.FOO], targetD);
		final targetE = new NormalTarget({number: 42});
		final targetEId = registry.addTarget([Types.FOO], targetE);
		final targetF = new TransformResultTarget(dropResult -> {number: (cast dropResult).number / 2});
		final targetFId = registry.addTarget([Types.BAR], targetF);
		final targetG = new NormalTarget({number: 100});
		final targetGId = registry.addTarget([Types.BAR], targetG);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetAId, targetBId, targetCId, targetDId, targetEId, targetFId, targetGId], {});
		backend.simulateDrop();
		backend.simulateEndDrag();
		asserts.assert(targetA.didCallDrop == true);
		asserts.assert(targetB.didCallDrop == true);
		asserts.assert(targetC.didCallDrop == false);
		asserts.assert(targetD.didCallDrop == true);
		asserts.assert(targetE.didCallDrop == true);
		asserts.assert(targetF.didCallDrop == false);
		asserts.assert(targetG.didCallDrop == false);
		asserts.compare({number: (42 + 1) * 2}, source.recordedDropResult);
		return asserts.done();
	}

	@:describe('always chooses parent drop result')
	public function alwaysChooseParentDropResult() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final targetA = new NormalTarget({number: 12345});
		final targetAId = registry.addTarget([Types.FOO], targetA);
		final targetB = new TransformResultTarget(dropResult -> {number: (cast dropResult).number * 2});
		final targetBId = registry.addTarget([Types.FOO], targetB);
		final targetC = new NonDroppableTarget();
		final targetCId = registry.addTarget([Types.FOO], targetC);
		final targetD = new TransformResultTarget(dropResult -> {number: (cast dropResult).number + 1});
		final targetDId = registry.addTarget([Types.FOO], targetD);
		final targetE = new NormalTarget({number: 42});
		final targetEId = registry.addTarget([Types.FOO], targetE);
		final targetF = new TransformResultTarget(dropResult -> {number: (cast dropResult).number / 2});
		final targetFId = registry.addTarget([Types.BAR], targetF);
		final targetG = new NormalTarget({number: 100});
		final targetGId = registry.addTarget([Types.BAR], targetG);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetAId, targetBId, targetCId, targetDId, targetEId, targetFId, targetGId,], {});
		backend.simulateDrop();
		backend.simulateEndDrag();
		asserts.assert(targetA.didCallDrop == true);
		asserts.assert(targetB.didCallDrop == true);
		asserts.assert(targetC.didCallDrop == false);
		asserts.assert(targetD.didCallDrop == true);
		asserts.assert(targetE.didCallDrop == true);
		asserts.assert(targetF.didCallDrop == false);
		asserts.assert(targetG.didCallDrop == false);
		asserts.compare({number: 12345}, source.recordedDropResult);
		return asserts.done();
	}

	@:describe('excludes removed targets when dispatching drop')
	public function excludeRemovedTargets() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final targetA = new NormalTarget();
		final targetAId = registry.addTarget([Types.FOO], targetA);
		final targetB = new NormalTarget();
		final targetBId = registry.addTarget([Types.FOO], targetB);
		final targetC = new NormalTarget();
		final targetCId = registry.addTarget([Types.FOO], targetC);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetAId, targetBId, targetCId], {});
		registry.removeTarget(targetBId);
		backend.simulateDrop();
		backend.simulateEndDrag();
		asserts.assert(targetA.didCallDrop == true);
		asserts.assert(targetB.didCallDrop == false);
		asserts.assert(targetC.didCallDrop == true);
		return asserts.done();
	}

	// 	// describe('hover()', () -> {

	@:describe('throws on hover after drop')
	public function throwOnHoverAfterDrop() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final target = new NormalTarget();
		final targetId = registry.addTarget([Types.FOO], target);
		asserts.assert(expectThrow(() -> backend.simulateHover([targetId], {})));
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetId], {});
		backend.simulateDrop();
		asserts.assert(expectThrow(() -> backend.simulateHover([targetId], {})));
		return asserts.done();
	}

	@:describe('throws on hover outside dragging operation')
	public function throwOnHoverOutsideDragging() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final target = new NormalTarget();
		final targetId = registry.addTarget([Types.FOO], target);
		asserts.assert(expectThrow(() -> backend.simulateHover([targetId], {})));
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetId], {});
		backend.simulateEndDrag();
		asserts.assert(expectThrow(() -> backend.simulateHover([targetId], {})));
		return asserts.done();
	}

	@:describe('excludes targets of different type when dispatching hover')
	public function excludeTargetOfDifferentType() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final targetA = new NormalTarget();
		final targetAId = registry.addTarget([Types.FOO], targetA);
		final targetB = new NormalTarget();
		final targetBId = registry.addTarget([Types.BAR], targetB);
		final targetC = new NormalTarget();
		final targetCId = registry.addTarget([Types.FOO], targetC);
		final targetD = new NormalTarget();
		final targetDId = registry.addTarget([Types.BAZ, Types.FOO], targetD);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetAId, targetBId, targetCId, targetDId], {});
		asserts.assert(targetA.didCallHover == true);
		asserts.assert(targetB.didCallHover == false);
		asserts.assert(targetC.didCallHover == true);
		asserts.assert(targetD.didCallHover == true);
		return asserts.done();
	}

	@:describe('includes non-droppable targets when dispatching hover')
	public function includeNonDroppableTargets() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final targetA = new TargetWithNoDropResult();
		final targetAId = registry.addTarget([Types.FOO], targetA);
		final targetB = new TargetWithNoDropResult();
		final targetBId = registry.addTarget([Types.FOO], targetB);
		backend.simulateBeginDrag([sourceId], {});
		backend.simulateHover([targetAId, targetBId], {});
		asserts.assert(targetA.didCallHover == true);
		asserts.assert(targetB.didCallHover == true);
		return asserts.done();
	}

	@:describe('throws in hover() if it contains the same target twice')
	public function throwIfContainsSameTargetTwice() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.BAR, source);
		final targetA = new NormalTarget();
		final targetAId = registry.addTarget([Types.BAR], targetA);
		final targetB = new NormalTarget();
		final targetBId = registry.addTarget([Types.BAR], targetB);
		backend.simulateBeginDrag([sourceId], {});
		asserts.assert(expectThrow(() -> backend.simulateHover([targetAId, targetBId, targetAId], {})));
		return asserts.done();
	}

	@:describe('throws in hover() if it contains the same target twice (even if wrong type)')
	public function throwIfContainsSameTargetTwice2() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final targetA = new NormalTarget();
		final targetAId = registry.addTarget([Types.BAR], targetA);
		final targetB = new NormalTarget();
		final targetBId = registry.addTarget([Types.BAR], targetB);
		backend.simulateBeginDrag([sourceId], {});
		asserts.assert(expectThrow(() -> backend.simulateHover([targetAId, targetBId, targetAId], {})));
		return asserts.done();
	}

	// @:describe('throws in hover() if it is called with a non-array')
	// public function throwIfNonArray() {
	// 	final source = new NormalSource();
	// 	final sourceId = registry.addSource(Types.FOO, source);
	// 	final target = new NormalTarget();
	// 	final targetId = registry.addTarget([Types.BAR], target);
	// 	backend.simulateBeginDrag([sourceId])
	// 	asserts.assert(expectThrow(() -> (backend as any).simulateHover(null));
	// 	asserts.assert(expectThrow(() -> (backend as any).simulateHover('yo'));
	// 	asserts.assert(expectThrow(() -> (backend as any).simulateHover(targetId));
	// }

	@:describe('throws in hover() if it contains an invalid drop target')
	public function throwsIfInvalidDropTarget() {
		final source = new NormalSource();
		final sourceId = registry.addSource(Types.FOO, source);
		final target = new NormalTarget();
		final targetId = registry.addTarget([Types.BAR], target);
		backend.simulateBeginDrag([sourceId], {});
		asserts.assert(expectThrow(() -> backend.simulateHover([targetId, null], {})));
		// asserts.assert(expectThrow(() -> backend.simulateHover([targetId, 'yo'], {})));
		// asserts.assert(expectThrow(() -> backend.simulateHover([targetId, sourceId], {})));
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
