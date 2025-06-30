# About DispatchAsync

DispatchAsync is a temporary experimental repository aimed at implementing missing Dispatch support in the SwiftWasm toolchain.
Currently, [SwiftWasm doesn't include Dispatch](https://book.swiftwasm.org/getting-started/porting.html#swift-foundation-and-dispatch). 
But, SwiftWasm does support Swift Concurrency. DispatchAsync implements a number of common Dispatch API's using Swift Concurrency
under the hood.

The code in this folder is copy-paste-adapted from [dispatch-async](https://github.com/PassiveLogic/dispatch-async).

Notes
- Copying here avoids adding a temporary new dependency on a repo that will eventually move into the Swift Wasm toolchain itself.
- This is a temporary measure to enable wasm compilation until dispatch-async is adopted into the SwiftWasm toolchain.
- The code is completely elided except for wasm compilation targets. 
- Only the minimum code needed for compilation is copied. 
