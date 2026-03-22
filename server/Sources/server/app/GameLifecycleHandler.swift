import Vapor

struct GameLifecycleHandler: LifecycleHandler {
  let clientManager: ClientManager

  func shutdown(_ application: Application) {
    let promise = application.eventLoopGroup.next().makePromise(of: Void.self)

    Task {
      await clientManager.clean()
      promise.succeed(())
    }

    try? promise.futureResult.wait()
  }
}
