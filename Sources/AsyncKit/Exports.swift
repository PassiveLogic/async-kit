#if canImport(NIOEmbedded)
@_documentation(visibility: internal) @_exported import class NIOEmbedded.EmbeddedEventLoop
#endif
@_documentation(visibility: internal) @_exported import protocol NIOCore.EventLoop
@_documentation(visibility: internal) @_exported import protocol NIOCore.EventLoopGroup
@_documentation(visibility: internal) @_exported import class NIOCore.EventLoopFuture
@_documentation(visibility: internal) @_exported import struct NIOCore.EventLoopPromise
#if canImport(NIOPosix)
@_documentation(visibility: internal) @_exported import class NIOPosix.MultiThreadedEventLoopGroup
#endif
