//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift.org project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift.org project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// # About DispatchAsync
///
/// DispatchAsync is a temporary experimental repository aimed at implementing missing Dispatch support in the SwiftWasm toolchain.
/// Currently, [SwiftWasm doesn't include Dispatch](https://book.swiftwasm.org/getting-started/porting.html#swift-foundation-and-dispatch)
/// But, SwiftWasm does support Swift Concurrency. DispatchAsync implements a number of common Dispatch API's using Swift Concurrency
/// under the hood.
///
/// The code in this folder is copy-paste-adapted from [swift-dispatch-async](https://github.com/PassiveLogic/swift-dispatch-async)
///
/// Notes
/// - Copying here avoids adding a temporary new dependency on a repo that will eventually move into the Swift Wasm toolchain itself.
/// - This is a temporary measure to enable wasm compilation until swift-dispatch-async is adopted into the SwiftWasm toolchain.
/// - The code is completely elided except for wasm compilation targets.
/// - Only the minimum code needed for compilation is copied.

#if os(WASI) && !canImport(Dispatch)

/// `DispatchQueue` is a drop-in replacement for the `DispatchQueue` implemented
/// in Grand Central Dispatch. However, this class uses Swift Concurrency, instead of low-level threading API's.
///
/// The primary goal of this implementation is to enable WASM support for Dispatch.
///
/// Refer to documentation for the original [DispatchQueue](https://developer.apple.com/documentation/dispatch/dispatchqueue)
/// for more details,
@available(macOS 10.15, *)
class DispatchQueue: @unchecked Sendable {
    static let main = DispatchQueue(isMain: true)

    private static let _global = DispatchQueue()
    static func global() -> DispatchQueue {
        Self._global
    }

    enum Attributes {
        case concurrent
    }

    private let targetQueue: DispatchQueue?

    /// Indicates whether calling context is running from the main DispatchQueue instance, or some other DispatchQueue instance.
    @TaskLocal static var isMain = false

    /// This is set during the initialization of the DispatchQueue, and controls whether `async` calls run on MainActor or not
    private let isMain: Bool
    private let label: String?
    private let attributes: DispatchQueue.Attributes?

    convenience init(
        label: String? = nil,
        attributes: DispatchQueue.Attributes? = nil,
        target: DispatchQueue? = nil
    ) {
        self.init(isMain: false, label: label, attributes: attributes, target: target)
    }

    private init(
        isMain: Bool,
        label: String? = nil,
        attributes: DispatchQueue.Attributes? = nil,
        target: DispatchQueue? = nil
    ) {
        self.isMain = isMain
        self.label = label
        self.attributes = attributes
        self.targetQueue = target
    }

    func async(
        execute work: @escaping @Sendable @convention(block) () -> Void
    ) {
        if let targetQueue, targetQueue !== self {
            // Recursively call this function on the target queue
            // until we reach a nil queue, or this queue.
            targetQueue.async(execute: work)
        } else {
            if isMain {
                Task { @MainActor [work] in
                    DispatchQueue.$isMain.withValue(true) { @MainActor [work] in
                        work()
                    }
                }
            } else {
                Task {
                    work()
                }
            }
        }
    }
}

#endif // #if os(WASI) && !canImport(Dispatch)
