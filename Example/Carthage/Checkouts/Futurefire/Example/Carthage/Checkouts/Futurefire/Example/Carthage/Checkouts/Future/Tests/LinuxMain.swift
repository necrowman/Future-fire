import XCTest

@testable import FutureTestSuite

XCTMain([
	testCase(EventTests.allTests),
	testCase(FutureTests.allTests),
	testCase(PromiseTests.allTests),
])