package;

import why.dragdrop.Context;
import tink.testrunner.*;
import tink.unit.*;

class RunTests {
	static function main() {
		Runner.run(TestBatch.make([
			// @formatter:off
			new ManagerTest(),
			// @formatter:on
		])).handle(Runner.exit);
	}
}
