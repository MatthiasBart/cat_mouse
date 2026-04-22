import Vapor

struct ShutdownHandler: LifecycleHandler {
  let roomsService: RoomsService
  func shutdown(_ application: Application) {
    let promise = application.eventLoopGroup.next().makePromise(of: Void.self)

    Task {
      await roomsService.clean()
      promise.succeed(())
    }

    try? promise.futureResult.wait()
  }
}
