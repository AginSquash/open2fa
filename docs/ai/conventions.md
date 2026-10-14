# Conventions

- ViewModels и сервисы с UI-состоянием — `@MainActor`.
- PBKDF2 не на main: `CryptoService.deriveKey` считает в `Task.detached`.
- Новые пароли (создание и смена): минимум 12 символов, не меньше 4 разных символов, короткий denylist. Импорт backup и unlock старого vault политику не применяют — иначе пользователь не восстановит данные.
- Локализация: ключ = английская строка в `Localizable.strings` (en + ru).
- Секреты, пароли, пути импорта не логировать. `_debugPrint` только в DEBUG.
- Keychain service `com.vladvrublevsky.open2fa.local`: salt, IV, KVC, KDF params. Без iCloud Keychain (`synchronizable(false)`, `whenUnlockedThisDeviceOnly`).
- AES-ключ только в `com.vladvrublevsky.open2fa.biometric` с `.biometryCurrentSet`. Fallback — пароль, не device passcode.
- `UserDefaults.alreadyInited` писать только после успешного создания vault.
- Нет KVC, но есть `alreadyInited` или ciphertext в Realm — не создавать новый KVC. Иначе старые аккаунты молча становятся нечитаемыми.
- Удаление аккаунта: IceCream soft-delete, но `account_data` и IV затираются.
- Не возвращать plaintext export. `O2FA_Unencrypted` удалён намеренно.
- Legacy MD5-AES (старый `.o2fa`) — только import, затем сразу re-encrypt текущей схемой.
