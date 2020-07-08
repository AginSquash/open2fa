
# <img src="https://github.com/AginSquash/open2fa/blob/master/open2fa_logo.png?raw=true" alt="Logo" width="40" height="40">  Open2FA

### Two-factor authentication app for iOS and macOS

[![Latest Release](https://img.shields.io/github/v/release/AginSquash/open2fa)](https://github.com/AginSquash/open2fa/releases)
![Platform](https://img.shields.io/badge/platform-ios%20%7C%20osx-lightgrey)
![Swift Version](https://img.shields.io/badge/Swift-5.0-orange.svg)


Open2FA is a simple, open source two-factor authentication application written using SwiftUI. Two-step verification helps you protect your accounts, even if attackers have your password.

- All your codes are stored in an encrypted file (AES-256) 🔐
- Codes can be added by QR scanning or manually  📷
- FaceID & TouchID support 👨‍🦱
- Your codes are not stored in iCloud ☁️

### Screenshots
<img src="https://github.com/AginSquash/open2fa/blob/master/screenshots/screenshot1.png?raw=true" width="250" alt="Screenshot of the Login screen" /> 
<img src="https://github.com/AginSquash/open2fa/blob/master/screenshots/screenshot2.png?raw=true" width="250" alt="Screenshot of the token list" /> 
<img src="https://github.com/AginSquash/open2fa/blob/master/screenshots/screenshot3.png?raw=true" width="250" alt="Screenshot of the edit list" />  &nbsp;

<img src="https://github.com/AginSquash/open2fa/blob/master/screenshots/screenshot4.png?raw=true" width="550" alt="Screenshot of the Authenticator token list" /> 


## Getting Started
 1. Download the latest version of the source code
 ?git clone https://github.com/AginSquash/open2fa.git
 2. Go to **open2fa** folder and open the **open2fa.xcodeproj** file.
 3. Wait until XCode downloads all dependencies and then run project.  


## Dependencies
All dependencies in this project are added through SPM. Links to them:
- https://github.com/lachlanbell/SwiftOTP
- https://github.com/krzyzanowskim/CryptoSwift
- https://github.com/twostraws/CodeScanner

## Notes
This product includes software developed by the "Marcin Krzyzanowski" (http://krzyzanowskim.com/)
Also i want to thank all the libraries developers and of course the wonderful SwiftUI community.

## License

Copyright (C) 2020 Vladislav Vrublevsky <agins.main@gmail.com>

This software is provided 'as-is', without any express or implied warranty.

In no event will the authors be held liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:

- The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
- Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
- This notice may not be removed or altered from any source or binary distribution.
- Redistributions of any form whatsoever must retain the following acknowledgment: 'This product includes software developed by the "Vladislav Vrublevsky" (AginSquash).'