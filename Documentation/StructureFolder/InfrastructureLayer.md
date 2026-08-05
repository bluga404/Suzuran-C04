## 2.3 Infrastructure Layer

## 2.3.1 Persistence

### File: Suzuran/Infrastructure/Persistence/KeyValueStore.swift
Peran:
- Abstraksi penyimpanan key-value.

Cuplikan kunci:
~~~swift
protocol KeyValueStore
~~~
Arti:
- App layer tidak terikat langsung ke UserDefaults.

### File: Suzuran/Infrastructure/Persistence/UserDefaultsKeyValueStore.swift
Peran:
- Implementasi KeyValueStore menggunakan UserDefaults.

Cuplikan kunci:
~~~swift
struct UserDefaultsKeyValueStore: KeyValueStore
~~~
Arti:
- Adapter konkret ke platform API.

## 2.3.2 Networking

### File: HTTPMethod.swift
- Enum method request.

### File: Endpoint.swift
- Definisi request contract: path, method, headers, query, body.

Cuplikan kunci:
~~~swift
struct Endpoint { let path: String; let method: HTTPMethod; ... }
~~~

### File: HTTPClient.swift
- Protokol client network.

Cuplikan kunci:
~~~swift
func send(baseURL: URL, endpoint: Endpoint) async throws -> (Data, HTTPURLResponse)
~~~

### File: URLSessionHTTPClient.swift
- Implementasi HTTPClient berbasis URLSession.

Cuplikan kunci:
~~~swift
let (data, response) = try await session.data(for: request)
~~~
Arti:
- Request async native Swift Concurrency.

Catatan penting:
- Infrastruktur networking sudah rapi, tetapi belum dipakai pada ExampleFeature karena data source masih mock.