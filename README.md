# auth0-duplicate-email
Users with duplicate non-unique Emails in Auth0

# Setup

## 1. Create a Database Connection
Name: unique

## 2. Create a custom non-migrating DB
Name: fixer
Turn on custom database and copy scripts from `custom-db/` folder.

## 3. Application
Create an M2M Application.
Allocate both `unique` and `fixer` connections to this app.
Assign Management API. All 'users' and 'ticket' scopes
Copy application details to `.env`, `server/env.php` files

## 4. Update fixer Custom DB Configuration
|| Name || Value ||
| Client_ID | M2M Client ID |
| Client_Secret | M2M Client Secret |
| Connection | unique |

## 6. Rule
Add `rules/merger.js` to Rules.

## 5. HLP

```js
    var lock = new Auth0Lock(config.clientID, config.auth0Domain, {
      // ....
      forgotPasswordLink: 'http://mycompany.com/forgotpassword.php'
    });
```
## 6. Forgotten Password Page

```bash
php -S localhost:8080 -t server
```

# Usage

## 1. Sign up a Users with Shared Email
```bash
./sign-up.sh -u user01 -m email@example.com -p password1
./sign-up.sh -u user02 -m email@example.com -p password2
./sign-up.sh -u user03 -m email@example.com -p password3
```

## 2. Sign in with Email
```
https://tenant.auth0.com/authroize?connection=fixer
```

### 3. Password Reset
In the login page, click on "forgotten password" link. Enter username for reset email.