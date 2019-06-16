// RUN: %target-swift-emit-silgen %s | %FileCheck %s

struct Pair<Element> {
  let first: Element
  let second: Element
}

extension<T> Pair where Element == T {
  // CHECK-LABEL: sil hidden [ossa] @$s33mangling_parameterized_extensions4PairVAAqd__Rszr__lE7genericyyF
  func generic() {}
}

extension<T> Pair where Element == T? {
  // CHECK-LABEL: sil hidden [ossa] @$s33mangling_parameterized_extensions4PairVAAqd__SgRszr__lE14firstUnwrappedqd__vg
  var firstUnwrapped: T { get {} }
}

extension<T: FixedWidthInteger> Pair<T> {
  // CHECK-LABEL: sil hidden [ossa] @$s33mangling_parameterized_extensions4PairVAAs17FixedWidthIntegerRzqd__Rszr__lE3sumxvg
  var sum: T { get {} }
}

extension<T> Pair<T?> {
  // CHECK-LABEL: sil hidden [ossa] @$s33mangling_parameterized_extensions4PairVAAqd__SgRszr__lE15secondUnwrappedqd__vg
  var secondUnwrapped: T { get {} }
}

extension<T> Pair<[T]> {
  // CHECK-LABEL: sil hidden [ossa] @$s33mangling_parameterized_extensions4PairVAASayqd__GRszr__lE12concatenatedADvg
  var concatenated: [T] { get {} }
}

extension Pair<String> {
  // CHECK-LABEL: sil hidden [ossa] @$s33mangling_parameterized_extensions4PairVAASSRszlE12firstLoweredSSvg
  var firstLowered: String { get {} }

  // CHECK-LABEL: sil hidden [ossa] @$s33mangling_parameterized_extensions4PairVAASSRszlE13secondLoweredSSvg
  var secondLowered: String { get {} }
}

extension<T> [T?] {
  // CHECK-LABEL: sil hidden [ossa] @$sSa33mangling_parameterized_extensionsqd__SgRszr__lE10someValuesSayqd__Gvg
  var someValues: [T] { get {} }
}

// CHECK-LABEL: sil hidden [ossa] @$s33mangling_parameterized_extensions4PairVAASQRzqd__Rszr__lE23__derived_struct_equalsySbACyxG_AEtFZ
extension<T: Equatable> Pair<T>: Equatable {}

extension<T> Collection where Element == T? {
  // CHECK-LABEL: sil hidden [ossa] @$sSl33mangling_parameterized_extensionsSlRzqd__Sg7ElementRtzr__lE9compactedSayqd__GyF
  func compacted() -> [T] {}
}
