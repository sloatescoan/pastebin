import Foundation
import SotoS3

struct Storage {
    // you could certainly implement this with a different backend

    let logger: Logger
    let s3: S3
    let bucket: String
    let prefix: String?

    init(logger: Logger, region: String, bucket: String, prefix: String? = nil) {
        // use environment to set up credentials
        self.logger = logger
        let client = AWSClient()
        self.s3 = S3(client: client, region: .init(awsRegionName: region))
        self.bucket = bucket
        self.prefix = prefix
    }

    func put(paste: String) async throws -> String {
        let key = UUID().uuidString + ".txt"
        let putObjectRequest = S3.PutObjectRequest(
            body: .init(string: paste),
            bucket: bucket,
            key: (prefix ?? "") + key
        )
        _ = try await s3.putObject(putObjectRequest)
        return key
    }

    func get(key: String) async throws -> ByteBuffer {
        let getObjectRequest = S3.GetObjectRequest(bucket: bucket, key: (prefix ?? "") + key)
        let response = try await s3.getObject(getObjectRequest)
        return try await response.body.collect(upTo: 10_000_000) // hard limit of 10MiB for now
    }
}
