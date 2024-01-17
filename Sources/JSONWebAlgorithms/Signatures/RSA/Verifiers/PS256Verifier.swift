/*
 * Copyright 2024 Gonçalo Frade
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import CryptoSwift
import Foundation
import JSONWebKey

struct PS256Verifier: Verifier {
    var algorithm: String { AvailableCrypto.RSASSA_PSS_WithSHA256_MGF1_WithSHA256.algorithm }
    var algorithmDescription: String { AvailableCrypto.RSASSA_PSS_WithSHA256_MGF1_WithSHA256.algorithmDescription }
    
    func verify(data: Data, signature: Data, key: JWK?) throws -> Bool {
        guard
            let n = key?.n,
            let e = key?.e
        else { throw CryptoError.notValidPrivateKey }
        let publicKey: RSA
        if
            let p = key?.p,
            let q = key?.q,
            let d = key?.d
        {
            publicKey = try RSA(n: BigUInteger(n), e: BigUInteger(e), d: BigUInteger(d), p: BigUInteger(p), q: BigUInteger(q))
        } else {
            publicKey = RSA(n: BigUInteger(n), e: BigUInteger(e), d: key?.d.map {BigUInteger($0)})
        }
        
        let secKey = try publicKey.getSecKey()
        guard SecKeyIsAlgorithmSupported(secKey, .sign, .rsaSignatureMessagePSSSHA256) else {
            throw CryptoError.algorithmNotSupported(alg: SecKeyAlgorithm.rsaSignatureMessagePSSSHA256.rawValue as String)
        }
        
        var verificationError: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(
            secKey,
            .rsaSignatureMessagePSSSHA256,
            data as CFData,
            signature as CFData,
            &verificationError
        )
        if let error = verificationError?.takeRetainedValue() as? NSError {
            throw CryptoError.securityLayerError(internalStatus: error.code, internalError: error)
        }
        
        return result
    }
}
