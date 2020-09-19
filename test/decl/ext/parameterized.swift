// RUN: %target-typecheck-verify-swift

struct Pair<Element> {
  var first: Element
  var second: Element
}

// Reject invalid extensions

struct BadScope {
  extension<T> Pair<T> {} // expected-error {{declaration is only valid at file scope}}
}

// Basic parameterized extensions

// Extend Pair where Element == Optional<T>
extension<T> Pair where Element == T? { // expected-note {{where 'Element' = 'Int', 'T?' = 'Optional<_>'}}
  var firstUnwrapped: T {
    first!
  }
}

let a = Pair<Int?>(first: 316, second: nil)
_ = a.firstUnwrapped // ok

let b = Pair<Int>(first: 316, second: 128)
_ = b.firstUnwrapped // expected-error {{property 'firstUnwrapped' requires the types 'Int' and 'Optional<_>' be equivalent}}

// Ensure we can extend types with same type requirements

// Extend Pair where Element == T, T: FixedWidthInteger
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
extension<T> Pair<T?> { // expected-note {{where 'Element' = 'Int', 'T?' = 'Optional<_>'}}
  var secondUnwrapped: T {
    second!
  }
}

let e = Pair<Int?>(first: nil, second: 128)
_ = e.secondUnwrapped // ok

let f = Pair<Int>(first: 316, second: 128)
_ = f.secondUnwrapped // expected-error {{property 'secondUnwrapped' requires the types 'Int' and 'Optional<_>' be equivalent}}

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
