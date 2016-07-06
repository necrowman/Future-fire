//===--- MutableFuture.swift ------------------------------------------------------===//
//Copyright (c) 2016 Daniel Leping (dileping)
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.
//===----------------------------------------------------------------------===//

import Foundation

import Result
import Boilerplate
import ExecutionContext

public protocol MutableFutureType {
    associatedtype Value
    
    func tryComplete<E : ErrorProtocol>(result:Result<Value, E>) -> Bool
}

internal class MutableFuture<V> : Future<V>, MutableFutureType {
    internal override init(context:ExecutionContextType) {
        super.init(context: context)
    }
    
    internal func tryComplete<E : ErrorProtocol>(result:Result<Value, E>) -> Bool {
        if self.result != nil {
            return false
        }
        
        self.result = result.asAnyError()
        return true
    }
}

public extension MutableFutureType {
    func complete<E : ErrorProtocol>(result:Result<Value, E>) throws {
        if !tryComplete(result) {
            throw Error.AlreadyCompleted
        }
    }
    
    func trySuccess(value:Value) -> Bool {
        return tryComplete(Result<Value, AnyError>(value:value))
    }
    
    func success(value:Value) throws {
        if !trySuccess(value) {
            throw Error.AlreadyCompleted
        }
    }
    
    func tryFail(error:ErrorProtocol) -> Bool {
        return tryComplete(Result(error: anyError(error)))
    }
    
    func fail(error:ErrorProtocol) throws {
        if !tryFail(error) {
            throw Error.AlreadyCompleted
        }
    }
    
    
    /// safe to be called several times
    func completeWith<F: FutureType where F.Value == Value>(f:F) {
        f.onComplete { (result:Result<Value, AnyError>) in
            self.tryComplete(result)
        }
    }
}