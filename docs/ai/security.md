# Security

## Модель

- Угрозы: украденный backup `.o2fa`, копия Realm, дамп RAM после background, snapshot в app switcher, другой код в процессе после unlock устройства, офлайн-брут пароля по salt+KVC.
- Не защищает от jailbreak при открытой сессии (ключ в RAM, пока grace-timeout не истёк) и от владельца Apple ID (private CloudKit).

## Контроли

- AES-256-GCM, отдельный nonce на запись. Тег 16 байт. Legacy IV 16 байт не читается CryptoKit — для v1 остаётся CryptoSwift.
- KDF v2: PBKDF2-HMAC-SHA256, 600_000 итераций, соль 16 байт из `SecRandomCopyBytes`. Иные числа итераций из сети не применяются (только 4096 и 600_000).
- Биометрический ключ: чтение/миграция legacy-ключа только с уже оценённым `LAContext`. Ошибка KVC → ключ удаляется.
- Lock на resign стирает plaintext и копию ключа в `CryptoService`. До timeout session key остаётся в RAM и список собирается заново. После timeout ключ читается из Keychain тем же `LAContext`; неуспех стирает session key и возвращает на пароль.
- Privacy shield — opaque `UIView` на window в `sceneWillResignActive`, до snapshot. SwiftUI blur сам по себе snapshot не закрывает.
- Буфер: `expirationDate` 60с, `localOnly`.
- Экспорт секрета аккаунта: повторный пароль/биометрия, затем decrypt одной записи из Realm (`accountForExport`), не из кэша OTP.
- Смена пароля и upgrade: если хоть один живой ciphertext не расшифровался — операция отменяется, vault не переписывается.
- `VaultMigrationWrap` закрывает окно Realm-записан / Keychain-ещё-старый.
- Cloud PED новее локального KDF → сброс биометрического ключа, pull, пароль. PED с чужими iterations игнорируется.

## Намеренно не сделано

- Argon2id нет в системе без новой зависимости; PBKDF2 600k — выбранный компромисс на iOS 15.
- Полное затирание Swift `String` пароля невозможно. Стирается `Data` ключа.
- Realm file не шифруется отдельно: секреты внутри ciphertext. Ключ не в файле Realm.
