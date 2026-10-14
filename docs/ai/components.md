# Components

- `CryptoService` — PBKDF2 (CommonCrypto), AES-GCM (CryptoKit + CryptoSwift для v1), salt, сравнение ключей.
- `KDFParams` — version, iterations, cipherVersion, saltIsBase64. `legacy` / `current`.
- `PasswordPolicy` — правила нового пароля.
- `KeychainService` — local items + biometric key. `apply(PublicEncryptData)`, `loadParams`.
- `BiometricAuthService.authenticatedContext()` — `LAContext` после успешной биометрии; тот же context передаётся в Keychain.
- `StorageService` — Realm schemaVersion 1 (`cipherVersion`, `VaultMigrationWrap`), sync write для re-encrypt, wipe on delete.
- `CloudKitService` — private DB, `PublicEncryptData`, после upload удаляет более старые PED-записи.
- `Core2FA_ViewModel` — unlock, biometric unlock, re-encrypt, lock/wipe, export одного секрета из Realm.
- `LoginViewModel` — флаги после успеха, подтягивание более нового PED, биометрия.
- `SensitivePasteboard` — OTP/secret в буфер с TTL 60с и `localOnly`.
- `SceneDelegate` — privacy shield.
- `ChangePasswordView` / `SecurityUpgradeView` — смена пароля и догоняющая миграция KDF.
