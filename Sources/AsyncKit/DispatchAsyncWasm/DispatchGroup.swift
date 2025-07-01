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
/// The code in this folder is copy-paste-adapted from [dispatch-async](https://github.com/PassiveLogic/dispatch-async)
///
/// Notes
/// - Copying here avoids adding a temporary new dependency on a repo that will eventually move into the Swift Wasm toolchain itself.
/// - This is a temporary measure to enable wasm compilation until dispatch-async is adopted into the SwiftWasm toolchain.
/// - The code is completely elided except for wasm compilation targets.
/// - Only the minimum code needed for compilation is copied.

#if os(WASI) && !canImport(Dispatch)

// MARK: - Interface for Non-Async Usage -

/// `DispatchGroup` is a drop-in replacement for the `DispatchGroup` implemented
/// in Grand Central Dispatch. However, this class uses Swift Concurrency, instead of low-level threading API's.
///
/// The primary goal of this implementation is to enable WASM support for Dispatch.
///
/// Refer to documentation for the original [DispatchGroup](https://developer.apple.com/documentation/dispatch/dispatchgroup)
/// for more details,
@available(macOS 10.15, *)
class DispatchGroup: @unchecked Sendable {
    /// Used to ensure FIFO access to the enter and leave calls
    @globalActor
    private actor DispatchGroupEntryActor: GlobalActor {
        static let shared = DispatchGroupEntryActor()
    }

    private let group = AsyncGroup()

    func enter() {
        Task { @DispatchGroupEntryActor [] in
            // ^--- Ensures serial FIFO entrance/exit into the group
            await group.enter()
        }
    }

    func leave() {
        Task { @DispatchGroupEntryActor [] in
            // ^--- Ensures serial FIFO entrance/exit into the group
            await group.leave()
        }
    }

    func notify(queue: DispatchQueue, execute work: @escaping @Sendable @convention(block) () -> Void) {
        Task { @DispatchGroupEntryActor [] in
            // ^--- Ensures serial FIFO entrance/exit into the group
            await group.notify {
                await withCheckedContinuation { continuation in
                    queue.async {
                        work()
                        continuation.resume()
                    }
                }
            }
        }
    }

    func wait() async {
        await group.wait()
    }

    init() {}
}

// MARK: - Private Interface for Async Usage -

@available(macOS 10.15, *)
fileprivate actor AsyncGroup {
    private var taskCount = 0
    private var continuation: CheckedContinuation<Void, Never>?
    private var isWaiting = false
    private var notifyHandlers: [@Sendable () async -> Void] = []

    func enter() {
        taskCount += 1
    }

    func leave() {
        defer {
            checkCompletion()
        }
        guard taskCount > 0 else {
            assertionFailure("leave() called more times than enter()")
            return
        }
        taskCount -= 1
    }

    func notify(handler: @escaping @Sendable () async -> Void) {
        notifyHandlers.append(handler)
        checkCompletion()
    }

    func wait() async {
        if taskCount <= 0 {
            return
        }

        isWaiting = true

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.continuation = continuation
            checkCompletion()
        }
    }

    private func checkCompletion() {
        if taskCount <= 0 {
            if isWaiting {
                continuation?.resume()
                continuation = nil
                isWaiting = false
            }

            if !notifyHandlers.isEmpty {
                let handlers = notifyHandlers
                notifyHandlers.removeAll()

                for handler in handlers {
                    Task {
                        await handler()
                    }
                }
            }
        }
    }
}

#endif // #if os(WASI) && !canImport(Dispatch)
