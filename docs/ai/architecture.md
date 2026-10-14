# Architecture

Open2FA — локальный 2FA vault (iOS 15+ / macOS 12+ / Catalyst), SwiftUI.

## Поток данных

- Пароль → PBKDF2-HMAC-SHA256 → AES-256 ключ.
- Проверка пароля: KVC (dummy `AccountData`, зашифрованный тем же ключом) в Keychain.
- Секреты аккаунтов: по одному `AccountObject` в Realm (IV + ciphertext). OTP считается в RAM после unlock.
- Опционально: AES-ключ в Keychain под biometry ACL; ciphertext аккаунтов в private CloudKit через IceCream.
- `PublicEncryptData` (salt, IV, KVC, параметры KDF) — Keychain + private CloudKit + файл `.o2fa`. Сам AES-ключ в iCloud не кладётся.

## Слои

- Views → ViewModels (`@MainActor`) → Services.
- `Core2FA_ViewModel` — сессия vault: ключ, расшифрованные аккаунты, таймер TOTP, lock.
- `LoginViewModel` — первый запуск, пароль, биометрия, cloud restore.
- `StorageService` — единственный Realm. `KeychainService` — секретный материал. `CryptoService` — KDF и AES-GCM.

## Форматы

- KDF v1: 4096 итераций, salt = UTF-8 строка, AES-GCM CryptoSwift, IV 16 байт. Только чтение старых vault/backup.
- KDF v2 (текущий): 600_000 итераций, salt = 16 случайных байт в base64, AES-GCM CryptoKit, nonce 12 байт.
- `AccountObject.cipherVersion`: 1 = legacy, 2 = CryptoKit. Версия на записи, не глобально.
- Экспорт `.o2fa`: `AccountsFileStruct`. Поле `accountsCipherVersion` (нет в старых файлах → считать 1).

## Lock

- `sceneWillResignActive`: непрозрачный privacy shield на `UIWindow` (snapshot app switcher).
- ViewModel: стирает plaintext и копию ключа в `CryptoService`, session key держит до полного lock.
- После timeout — биометрия или сброс сессии и возврат на пароль. На Catalyst те же уведомления и shield.

## Миграция KDF

- При unlock паролем, если параметры старше v2: расшифровать все живые аккаунты, перешифровать, записать Realm и `VaultMigrationWrap` одной транзакцией, затем обновить Keychain и удалить wrap.
- Wrap — локальный объект Realm, не синхронизируется IceCream. Нужен, чтобы обрыв между Realm и Keychain поднимался на следующем unlock.
- Биометрия без пароля миграцию не делает. Если cloud PED новее локального — локальный биометрический ключ сбрасывается, нужен пароль.
- Смена пароля — тот же re-encrypt с новой солью и текущим KDF.
