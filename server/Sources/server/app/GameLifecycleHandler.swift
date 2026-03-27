import Vapor

struct GameLifecycleHandler: LifecycleHandler {
  let clientsService: ClientsService

  func shutdown(_ application: Application) {
    let promise = application.eventLoopGroup.next().makePromise(of: Void.self)

    Task {
      await clientsService.clean()
      promise.succeed(())
    }

    try? promise.futureResult.wait()
  }
}
