import ArgumentParser
import Hummingbird
import Logging
import Templ
import HummingbirdTempl

@main
struct AppCommand: AsyncParsableCommand, AppArguments {
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 5080

    @Option(name: .shortAndLong)
    var logLevel: Logger.Level?

    func run() async throws {
        let app = try await buildApplication(self)

        let environment = Environment(loader: FileSystemLoader(paths: ["web/templates/"]))
        try TemplConfig.set(TemplConfig(environment: environment))

        try await app.runService()
    }
}

/// Extend `Logger.Level` so it can be used as an argument
#if hasFeature(RetroactiveAttribute)
    extension Logger.Level: @retroactive ExpressibleByArgument {}
#else
    extension Logger.Level: ExpressibleByArgument {}
#endif
