// RUN: %target-typecheck-verify-swift

struct Pair<Element> {
  var first: Element
  var second: Element
}

// Basic parameterized extensions

// Extend Pair where Element == Optional<T>
extension<T> Pair where Element == T? { // expected-note {{where 'Element' = 'Int', 'T?' = '_?'}}
  var firstUnwrapped: T {
    first!
  }
}

let a = Pair<Int?>(first: 316, second: nil)
_ = a.firstUnwrapped // ok

let b = Pair<Int>(first: 316, second: 128)
_ = b.firstUnwrapped // expected-error {{property 'firstUnwrapped' requires the types 'Int' and '_?' be equivalent}}

// Ensure we can extend types with same type requirements

// Extend Pair where Element == T: FixedWidthInteger
extension<T: FixedWidthInteger> Pair<T> { // expected-note {{where 'Element' = 'Double'}}
  var sum: T {
    first + second
  }
}

let c = Pair<Int>(first: 316, second: 128)
_ = c.sum // ok

let d = Pair<Double>(first: .pi, second: .zero)
_ = d.sum // expected-error {{property 'sum' requires that 'Double' conform to 'FixedWidthInteger'}}

// Extend Pair where Element == Optional<T>
extension<T> Pair<T?> { // expected-note {{where 'Element' = 'Int', 'T?' = '_?'}}
  var secondUnwrapped: T {
    second!
  }
}

let e = Pair<Int?>(first: nil, second: 128)
_ = e.secondUnwrapped // ok

let f = Pair<Int>(first: 316, second: 128)
_ = f.secondUnwrapped // expected-error {{property 'secondUnwrapped' requires the types 'Int' and '_?' be equivalent}}

// Extend Pair where Element == Array<T>
extension<T> Pair<[T]> { // expected-note {{where 'Element' = 'Set<Int>', '[T]' = '[Any]'}}
                         // expected-note@-1 {{'T' declared as parameter to type 'Pair'}}
  var concatenated: [T] {
    first + second
  }
}

let g = Pair<[Int]>(first: [1, 2, 3], second: [4, 5, 6])
_ = g.concatenated // ok

let h = Pair<Set<Int>>(first: [1, 2, 3], second: [4, 5, 6])
_ = h.concatenated // expected-error {{generic parameter 'T' could not be inferred}}
                   // expected-error@-1 {{property 'concatenated' requires the types 'Set<Int>' and '[Any]' be equivalent}}

// Ensure we can extend specialized types

// Extend Pair where Element == String
extension Pair<String> { // expected-note {{where 'Element' = '[Character]'}}
                         // expected-note@-1 {{where 'Element' = '[Character]'}}
  var firstLowered: String {
    first.lowercased()
  }

  var secondLowered: String {
    second.lowercased()
  }
}

let i = Pair<String>(first: "Hello", second: "Hey")
_ = i.firstLowered // ok
_ = i.secondLowered // ok

let j = Pair<[Character]>(first: ["H", "e", "l", "l", "o"], second: ["H", "e", "y"])
_ = j.firstLowered // expected-error {{property 'firstLowered' requires the types '[Character]' and 'String' be equivalent}}
_ = j.secondLowered // expected-error {{property 'secondLowered' requires the types '[Character]' and 'String' be equivalent}}

// Ensure we can extend sugar types

// Extend Array where Element == Optional<T>
extension<T> [T?] { // expected-note {{where 'Element' = 'Int', 'T?' = 'Any?'}}
                    // expected-note@-1 {{'T' declared as parameter to type 'Array'}}
  var someValues: [T] {
    var result = [T]()
    for opt in self {
      if let value = opt { result.append(value) }
    }

    return result
  }
}

let k = [1, 2, nil, 4]
_ = k.someValues // ok

let l = [1, 2, 3, 4]
_ = l.someValues // expected-error {{generic parameter 'T' could not be inferred}}
                 // expected-error@-1 {{property 'someValues' requires the types 'Int' and 'Any?' be equivalent}}

// Cannot extend generic type parameters

extension<T> T { // expected-error {{cannot extend generic parameter type 'T'}}
  func sayHello() {
    print("Hello!")
  }
}

protocol X {}
protocol Y {}

extension<T: X> T: Y { // expected-error {{cannot extend generic parameter type 'T'}}
  func sayGoodbye() {
    print("Goodbye!")
  }
}

// Conditional Conformance (!!!)

struct Wrapped<T> {
  let value: T
}

extension<T: Equatable> Pair<T>: Equatable {} // expected-note {{requirement from conditional conformance of 'Pair<Wrapped<Int>>' to 'Equatable'}}

let m = Pair<Int>(first: 316, second: 128)
let n = Pair<Int>(first: 316, second: 128)
_ = m == n // ok

let o = Pair<Wrapped<Int>>(first: .init(value: 316), second: .init(value: 128))
let p = Pair<Wrapped<Int>>(first: .init(value: 316), second: .init(value: 128))
_ = o == p // expected-error {{operator function '==' requires that 'Wrapped<Int>' conform to 'Equatable'}}

// Protocol Extensions

extension<T> Collection where Element == T? { // expected-note {{where 'Self.Element' = 'Int', 'T?' = 'Any?'}}
                                              // expected-note@-1 {{'T' declared as parameter to type 'Collection'}}
  func compacted() -> [T] {
    compactMap { $0 }
  }
}

let q = [1, 2, nil, 4]
_ = q.compacted() // ok

let r = [1, 2, 3, 4]
_ = r.compacted() // expected-error {{generic parameter 'T' could not be inferred}}
                  // expected-error@-1 {{referencing instance method 'compacted()' on 'Collection' requires the types 'Int' and 'Any?' be equivalent}}
