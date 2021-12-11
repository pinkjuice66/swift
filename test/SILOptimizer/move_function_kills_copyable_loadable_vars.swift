// RUN: %target-swift-frontend -enable-experimental-move-only -verify %s -parse-stdlib -emit-sil -o /dev/null

// REQUIRES: optimized_stdlib

import Swift

public class Klass {}

//////////////////
// Declarations //
//////////////////

func consumingUse(_ k: __owned Klass) {}
var booleanValue: Bool { false }
var booleanValue2: Bool { false }
func nonConsumingUse(_ k: Klass) {}

///////////
// Klassests //
///////////

public func performMoveOnVarSingleBlock(_ p: Klass) {
    var x = p
    let _ = _move(x)
    x = p
    nonConsumingUse(x)
}

public func performMoveOnVarSingleBlockError(_ p: Klass) {
    var x = p // expected-error {{'x' used after being moved}}
    let _ = _move(x) // expected-note {{move here}}
    nonConsumingUse(x) // expected-note {{use here}}
    x = p
    nonConsumingUse(x)
}

public func performMoveOnVarMultiBlock(_ p: Klass) {
    var x = p
    let _ = _move(x)

    while booleanValue {
        print("true")
    }

    while booleanValue {
        print("true")
    }

    x = p
    nonConsumingUse(x)
}

public func performMoveOnVarMultiBlockError1(_ p: Klass) {
    var x = p // expected-error {{'x' used after being moved}}
    let _ = _move(x) // expected-note {{move here}}

    nonConsumingUse(x) // expected-note {{use here}}

    while booleanValue {
        print("true")
    }

    // We only emit an error on the first one.
    nonConsumingUse(x)

    while booleanValue {
        print("true")
    }

    // We only emit an error on the first one.
    nonConsumingUse(x)

    x = p
    nonConsumingUse(x)
}

public func performMoveOnVarMultiBlockError2(_ p: Klass) {
    var x = p // expected-error {{'x' used after being moved}}
    let _ = _move(x) // expected-note {{move here}}

    while booleanValue {
        print("true")
    }

    nonConsumingUse(x) // expected-note {{use here}}

    while booleanValue {
        print("true")
    }

    // We only error on the first one.
    nonConsumingUse(x)

    x = p
    nonConsumingUse(x)
}

public func performMoveConditionalReinitalization(_ p: Klass) {
    var x = p

    if booleanValue {
        nonConsumingUse(x)
        let _ = _move(x)
        x = p
        nonConsumingUse(x)
    } else {
        nonConsumingUse(x)
    }

    nonConsumingUse(x)
}

public func performMoveConditionalReinitalization2(_ p: Klass) {
    var x = p // expected-error {{'x' used after being moved}}

    if booleanValue {
        nonConsumingUse(x)
        let _ = _move(x) // expected-note {{move here}}
        nonConsumingUse(x) // expected-note {{use here}}
        x = p
        nonConsumingUse(x)
    } else {
        nonConsumingUse(x)
    }

    nonConsumingUse(x)
}

public func performMoveConditionalReinitalization3(_ p: Klass, _ p2: Klass, _ p3: Klass) {
    var x = p // expected-error {{'x' used after being moved}}
              // expected-error @-1 {{'x' used after being moved}}

    if booleanValue {
        nonConsumingUse(x)
        let _ = _move(x)   // expected-note {{move here}}
        nonConsumingUse(x) // expected-note {{use here}}
        nonConsumingUse(x) // We only emit for the first one.
        x = p2
        nonConsumingUse(x)
        let _ = _move(x)   // expected-note {{move here}}
        nonConsumingUse(x) // expected-note {{use here}}
    } else {
        nonConsumingUse(x)
    }

    nonConsumingUse(x)
}

// Even though the examples below are for lets, since the let is not initially
// defined it comes out like a var.
public func performMoveOnLaterDefinedInit(_ p: Klass) {
    let x: Klass // expected-error {{'x' used after being moved}}
    do {
        x = p
    }
    let _ = _move(x) // expected-note {{move here}}
    nonConsumingUse(x) // expected-note {{use here}}
}

public func performMoveOnLaterDefinedInit2(_ p: Klass) {
    let x: Klass
    do {
        x = p
    }
    nonConsumingUse(x)
    let _ = _move(x)
}
