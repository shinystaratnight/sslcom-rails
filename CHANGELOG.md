# Changelog
All notable changes to this project will be documented in this file.

### PENDING RELEASE (TBD)
- Update Code Deploy AWS configuration
- Update doc signing calls to EJBCA to remove email addresses and use different EJBCA profiles
- Redirect to initially requested URL, after login and DUO authentication
- Fix button alignment on the registrant edit screen
- fix csr verify signature

### v1.5.0 (August 4, 2020)

- Fix CDN edit page looking so messy (it was all over place)
- Update config/webpacker.yml to fix webpacker fallback during testing.
- Show clickable link for confirmation in flash message
- Pre-select team when editing user roles
- Do not return SslAccount in API query if the user is a member with only role Role::INDIVIDUAL_CERTIFICATE
- Fix email addresses return for dcv query (reversed Comodo/SSL.com look ups)

### v1.4.2 (July 29, 2020)

- Disable use of 2FA according to Settings.u2f_enabled

### v1.4.1 (July 29, 2020)

- Remove Olark chat and add HubSpot chat

### v1.4.0 (July 24, 2020)

- Fix issue creating duplicate accounts on signup or invite
- Show domain names that do not pass CAA check
- return status 400 for failed API submits
- added function to add weak keys
- remove address information requirement for API submit
- remove validation check for presence of CN field in CSR
- Bug fix for nil exception ApiCertificateCreate_v1_4#get_domain
- Add product filtering option for phone callback approvals and verifications page.
- Assign CA profile to Business Identity Enterprise product
- Fix Url Callback function
- Fix creating 2 SslAccount objects when creating a User account
- Bug fix to ensure monthly billing users can place invoiced orders via API without checking funded_account or billing_profiles.
- Fix errors when saving screenshots on ci failure
- Add ability to elevate a user to super_user or sys_admin programatically.
- Enable 2FA for all users (security key and OTP via twillio)
- Uncommented out code that checked for SMIME emailed token's expiration date
- Correct pagination display and certificate order rendering for phone
  approval and verifications view.
- Fixed issue creating two teams for every new account and setting both of them to default.

### v1.3.4 (July 10th, 2020)

- Add automatic phone approval queueing for certificate orders
- Add rescue_from exception for Authlogic::Session::Activation::NotActivatedError

### v1.3.3 (July 1st, 2020)

- Revert certificate order search and find_certificate cache.

### v1.3.2 (July 1st, 2020)

- Additional bug fix patch for sp-592 locked_registrant view

### v1.3.1 (June 29, 2020)

- Allow document upload on verified orders

### v1.3.0 (June 29, 2020)

- Created changelog for tracking codebase changes
- Added test coverage upload for CodeClimate
- Fixed test coverage upload for CodeClimate
- Update CertificateOrder.search_with_csr to include contacts
- Move CertificateOrder scopes to a Concern
- Lock Rubocop Version to match Code CodeClimate
- Create a Dashboard for Phone Approval and Verification Management

### v1.2.0 (June 17, 2020)

- Implement trademark validation engine
