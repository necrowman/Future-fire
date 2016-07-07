//
//  PromiseTests.swift
//  Future
//
//  Created by Yegor Popovych on 4/11/16.
//  Copyright © 2016 Crossroad Labs, LTD. All rights reserved.
//

import XCTest
import XCTest3
import Future
import ExecutionContext
import Boilerplate
import Result

class PromiseTests: XCTestCase {
    
    func testSuccessPromise() {
        let p = Promise<Int>()
        global.async {
            try! p.success(fibonacci(10))
        }
        
        let e = self.expectation(withDescription: "complete expectation")
        
        p.future.onComplete { (result:Result<Int, AnyError>) in
            switch result {
            case .Success(let val):
                XCTAssert(Int(55) == val)
            case .Failure(_):
                XCTAssert(false)
            }
            
            e.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testFailurePromise() {
        let p = Promise<Int>()
        
        global.async {
            p.tryFail(TestError.Recoverable)
        }
        
        let e = self.expectation(withDescription: "complete expectation")
        
        p.future.onComplete { (result:Result<Int, TestError>) in
            switch result {
            case .Success(_):
                XCTFail("should not be success")
            case .Failure(let err):
                XCTAssertEqual(err, TestError.Recoverable)
            }
            
            e.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }
    
//    func testCompletePromise() {
//        let p = Promise<Int>()
//        try! p.complete(Result<Int, AnyError>(value: 2))
//        
//        XCTAssertEqual(p.future.value, 2)
//    }
    
    func testPromiseCompleteWithSuccess() {
        let p = Promise<Int>()
        p.tryComplete(Result<Int, TestError>(value: 2))
        
        XCTAssert(p.future.isCompleted)
        //XCTAssert(p.future.result() == Result<Int, TestError>(value:2))
    }
    
    func testPromiseCompleteWithFailure() {
        let p = Promise<Int>()
        p.tryComplete(Result(error: TestError.Recoverable))
        
        XCTAssert(p.future.isCompleted)
        //XCTAssert(p.future.result() == Result<Int, TestError>(error:TestError.Recoverable))
    }
    
//    func testPromiseTrySuccessTwice() {
//        let p = Promise<Int>()
//        XCTAssert(p.trySuccess(1))
//        XCTAssertFalse(p.trySuccess(2))
//        XCTAssertEqual(p.future.result().value!, 1)
//    }
    
//    func testPromiseTryFailureTwice() {
//        let p = Promise<Int>()
//        XCTAssert(p.tryFail(TestError.Recoverable))
//        XCTAssertFalse(p.tryFail(TestError.Fatal))
//        XCTAssertEqual(p.future.result().error!, TestError.Recoverable)
//    }
    
    func testPromiseCompleteWithSucceedingFuture() {
        let p = Promise<Int>()
        let q = Promise<Int>()
        
        p.completeWith(q.future)
        
        XCTAssert(!p.future.isCompleted)
        try! q.success(1)
        // XCTAssertEqual(p.future.value, 1)
    }
    
    func testPromiseCompleteWithFailingFuture() {
        let p = Promise<Int>()
        let q = Promise<Int>()
        
        p.completeWith(q.future)
        
        XCTAssert(!p.future.isCompleted)
        try! q.fail(TestError.Recoverable)
        //XCTAssertEqual(p.future.result().error!, TestError.Recoverable)
    }
}

#if os(Linux)
extension PromiseTests {
	static var allTests : [(String, PromiseTests -> () throws -> Void)] {
		return [
			("testSuccessPromise", testSuccessPromise),
			("testFailurePromise", testFailurePromise),
//			("testCompletePromise", testCompletePromise),
			("testPromiseCompleteWithSuccess", testPromiseCompleteWithSuccess),
			("testPromiseCompleteWithFailure", testPromiseCompleteWithFailure),
//			("testPromiseTrySuccessTwice", testPromiseTrySuccessTwice),
//			("testPromiseTryFailureTwice", testPromiseTryFailureTwice),
			("testPromiseCompleteWithSucceedingFuture", testPromiseCompleteWithSucceedingFuture),
			("testPromiseCompleteWithFailingFuture", testPromiseCompleteWithFailingFuture),
		]
	}
}
#endif