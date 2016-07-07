//===--- EventOnce.swift ------------------------------------------------------===//
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

import Boilerplate
import ExecutionContext
import Result
import Event

public extension EventEmitterProtocol {
    public func once<E : EventProtocol>(event: E, failOnError:(ErrorProtocol)->Bool = {_ in true}) -> Future<E.Payload> {
        let future = MutableFuture<E.Payload>(context: immediate)
        
        let offEvent = self.on(event).react { payload in
            future.trySuccess(payload)
        }
        
        let offError = self.on(.error).react { e in
            if failOnError(e) {
                future.tryFail(e)
            }
        }
        
        future.onComplete { (_:Result<E.Payload,AnyError>) in
            offEvent()
            offError()
        }

        return future
    }
}
