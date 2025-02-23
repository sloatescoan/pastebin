import Logging
import Hummingbird
import HummingbirdMacroRouting
import Templ
import HummingbirdTempl

@MacroRouting
struct PasteController<Context: RequestContext> {

    let logger: Logger
    let secret: String
    let storage: Storage
    let cookieName = "remember"

    @GET("/")
    @Sendable func getRoot(request: Request, context: Context) async throws -> TemplResponse {
        let err: String? = request.uri.queryParameters.get("err")
        let cookieSecret = request.cookies[self.cookieName]?.value

        let alreadyHasCookie = cookieSecret == self.secret
        if alreadyHasCookie {
            logger.info("\(#file):\(#function) Skipping 'remember' UI; request already has a correct cookie.")
        }

        return .init(
            template: "home.html",
            templateContext: [
                "err": err as Any, // Templ could do better here
                "pasteHandlerUrl": $Routing.postPaste.path,
                "showSecretInput": !alreadyHasCookie
            ],
            status: (err == nil) ? .ok : .badRequest
        )
    }

    @POST("/paste")
    @Sendable func postPaste(request: Request, context: Context) async throws -> Response {
        var setCookie = false

        // default back to the main page
        var redirect = Response(status: .seeOther, headers: [.location: $Routing.getRoot.path])

        let input: SubmissionInput
        do {
            input = try await request.decode(as: SubmissionInput.self, context: context)
            logger.info("\(#file):\(#function) Received valid input.")
        } catch {
            logger.warning("\(#file):\(#function) Received invalid input.")
            redirect.headers[.location] = "\($Routing.getRoot.path)?err=input"
            return redirect
        }

        guard
            input.secret == self.secret
            ||
            request.cookies[self.cookieName]?.value == self.secret
        else {
            logger.warning("\(#file):\(#function) Secret is incorrect.")
            redirect.setCookie(.init(name: self.cookieName, value: "", httpOnly: true))
            redirect.headers[.location] = "\($Routing.getRoot.path)?err=secret"
            return redirect
        } 

        if input.remember != nil {
            setCookie = true
        }

        let key: String
        do {
            key = try await storage.put(paste: input.paste)
            logger.info("\(#file):\(#function) Wrote to key: \(key)")
        } catch {
            // failed to write
            logger.warning("\(#file):\(#function) Could not write to storage. Error: \(error)")
            return .init(status: .internalServerError, body: .init(byteBuffer: .init(string: "Could not write to storage.")))
        }

        if setCookie {
            // we store this as plaintext; it's low-value
            // if we get here, the user has authenticated so we can use self.secret
            logger.info("\(#file):\(#function) Setting the secret cookie.")
            redirect.setCookie(.init(name: self.cookieName, value: self.secret, maxAge: 31536000, httpOnly: true))
        }

        redirect.headers[.location] = $Routing.getPaste.path.replacing(":key", with: key) // MacroRouting could do this better
        return redirect
    }

    @GET("/p/:key")
    @Sendable func getPaste(request: Request, context: Context) async throws -> TemplResponse {

        guard let key = context.parameters.get("key") else {
            logger.warning("\(#file):\(#function) Could not get key from request.")
            throw HTTPError(.badRequest)
        }
        do {
            logger.info("\(#file):\(#function) Fetching key: \(key)")
            let body = try await storage.get(key: key)
            logger.info("\(#file):\(#function) Fetched key: \(key)")
            return .init(
                status: .ok,
                headers: [.contentType: "text/plain"],
                body: .init(byteBuffer: body)
            )
        } catch {
            // did not fetch key
            logger.warning("\(#file):\(#function) Could not fetch key: \(error)")
            return .init(status: .notFound)
        }
    }
}
