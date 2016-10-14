/*
 * Copyright (C) 2015 - 2016, Daniel Dahan and CosmicMind, Inc. <http://cosmicmind.io>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *	*	Redistributions of source code must retain the above copyright notice, this
 *		list of conditions and the following disclaimer.
 *
 *	*	Redistributions in binary form must reproduce the above copyright notice,
 *		this list of conditions and the following disclaimer in the documentation
 *		and/or other materials provided with the distribution.
 *
 *	*	Neither the name of CosmicMind nor the names of its
 *		contributors may be used to endorse or promote products derived from
 *		this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import XCTest
@testable import Graph

class ActionThreadTests : XCTestCase, WatchActionDelegate {
    var insertSaveExpectation: XCTestExpectation?
    var insertExpectation: XCTestExpectation?
    var insertPropertyExpectation: XCTestExpectation?
    var insertTagExpectation: XCTestExpectation?
    var updateSaveExpectation: XCTestExpectation?
    var updatePropertyExpectation: XCTestExpectation?
    var deleteSaveExpectation: XCTestExpectation?
    var deleteExpectation: XCTestExpectation?
    var deletePropertyExpectation: XCTestExpectation?
    var deleteTagExpectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAll() {
        insertSaveExpectation = expectation(description: "Test: Save did not pass.")
        insertExpectation = expectation(description: "Test: Insert did not pass.")
        insertPropertyExpectation = expectation(description: "Test: Insert property did not pass.")
        insertTagExpectation = expectation(description: "Test: Insert tag did not pass.")
        
        let q1 = DispatchQueue(label: "io.cosmicmind.graph.thread.1", attributes: .concurrent)
        let q2 = DispatchQueue(label: "io.cosmicmind.graph.thread.2", attributes: .concurrent)
        let q3 = DispatchQueue(label: "io.cosmicmind.graph.thread.3", attributes: .concurrent)
        
        let graph = Graph()
        let watch = Watch<Action>(graph: graph).for(types: "T").has(tags: "G").where(properties: "P").resume()
        watch.delegate = self
        
        let action = Action(type: "T")
        
        q1.async { [weak self] in
            action["P"] = 111
            action.add(tag: "G")
            
            graph.async { [weak self] (success, error) in
                XCTAssertTrue(success, "\(error)")
                self?.insertSaveExpectation?.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        updateSaveExpectation = expectation(description: "Test: Save did not pass.")
        updatePropertyExpectation = expectation(description: "Test: Update did not pass.")
        
        q2.async { [weak self] in
            action["P"] = 222
            
            graph.async { [weak self] (success, error) in
                XCTAssertTrue(success, "\(error)")
                self?.updateSaveExpectation?.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        deleteSaveExpectation = expectation(description: "Test: Save did not pass.")
        deleteExpectation = expectation(description: "Test: Delete did not pass.")
        deletePropertyExpectation = expectation(description: "Test: Delete property did not pass.")
        deleteTagExpectation = expectation(description: "Test: Delete tag did not pass.")
        
        q3.async { [weak self] in
            action.delete()
            
            graph.async { [weak self] (success, error) in
                XCTAssertTrue(success, "\(error)")
                self?.deleteSaveExpectation?.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func watch(graph: Graph, inserted action: Action, source: GraphSource) {
        XCTAssertEqual("T", action.type)
        XCTAssertTrue(0 < action.id.characters.count)
        XCTAssertEqual(111, action["P"] as? Int)
        XCTAssertTrue(action.has(tag: "G"))
        
        insertExpectation?.fulfill()
    }
    
    func watch(graph: Graph, deleted action: Action, source: GraphSource) {
        XCTAssertEqual("T", action.type)
        XCTAssertTrue(0 < action.id.characters.count)
        XCTAssertNil(action["P"])
        XCTAssertFalse(action.has(tag: "G"))
        
        deleteExpectation?.fulfill()
    }
    
    func watch(graph: Graph, action: Action, added tag: String, source: GraphSource) {
        XCTAssertEqual("T", action.type)
        XCTAssertEqual("G", tag)
        XCTAssertTrue(action.has(tag: tag))
        
        insertTagExpectation?.fulfill()
    }
    
    func watch(graph: Graph, action: Action, removed tag: String, source: GraphSource) {
        XCTAssertEqual("T", action.type)
        XCTAssertTrue(0 < action.id.characters.count)
        XCTAssertEqual("G", tag)
        XCTAssertFalse(action.has(tag: "G"))
        
        deleteTagExpectation?.fulfill()
    }
    
    func watch(graph: Graph, action: Action, added property: String, with value: Any, source: GraphSource) {
        XCTAssertEqual("T", action.type)
        XCTAssertTrue(0 < action.id.characters.count)
        XCTAssertEqual("P", property)
        XCTAssertEqual(111, value as? Int)
        XCTAssertEqual(value as? Int, action[property] as? Int)
        
        insertPropertyExpectation?.fulfill()
    }
    
    func watch(graph: Graph, action: Action, updated property: String, with value: Any, source: GraphSource) {
        XCTAssertEqual("T", action.type)
        XCTAssertTrue(0 < action.id.characters.count)
        XCTAssertEqual("P", property)
        XCTAssertEqual(222, value as? Int)
        XCTAssertEqual(value as? Int, action[property] as? Int)
        
        updatePropertyExpectation?.fulfill()
    }
    
    func watch(graph: Graph, action: Action, removed property: String, with value: Any, source: GraphSource) {
        XCTAssertEqual("T", action.type)
        XCTAssertTrue(0 < action.id.characters.count)
        XCTAssertEqual("P", property)
        XCTAssertEqual(222, value as? Int)
        XCTAssertNil(action[property])
        
        deletePropertyExpectation?.fulfill()
    }
}
