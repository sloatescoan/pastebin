import Hummingbird
import Logging
import SotoS3

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable. 
/// Any variables added here also have to be added to `App` in App.swift and 
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "pastebin")
        logger.logLevel = 
            arguments.logLevel ??
            environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ??
            .info
        return logger
    }()
    let router = buildRouter(logger: logger)
    let app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "pastebin"
        ),
        logger: logger
    )
    return app
}

/// Build router
func buildRouter(logger: Logger) -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
        FileMiddleware(
            "web/public"
        )
    }

    // check these at routing assignment so we can fail early if they're missing
    let env = Hummingbird.Environment()
    guard let secret = env.get("SUBMIT_SECRET") else {
        fatalError("Set `SUBMIT_SECRET` in the environmemt.")
    }
    guard let bucket = env.get("S3_BUCKET") else {
        fatalError("Set `S3_BUCKET` in the environmemt.")
    }
    let prefix = env.get("S3_KEY_PREFIX")
    let storage = Storage(
        logger: logger,
        region: env.get("AWS_REGION") ?? "us-east-1", // we can default this one
        bucket: bucket,
        prefix: prefix
    )

    router.addRoutes(PasteController(logger: logger, secret: secret, storage: storage).$routes)

    return router
}
