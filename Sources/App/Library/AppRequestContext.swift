import Hummingbird

struct AppRequestContext: RequestContext {
    init(source: Hummingbird.ApplicationRequestContextSource) {
        coreContext = .init(source: source)
    }

    var coreContext: Hummingbird.CoreRequestContextStorage
    var requestDecoder: URLEncodedFormDecoder { .init() }
}
