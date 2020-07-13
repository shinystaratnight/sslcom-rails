# Changelog
All notable changes to this project will be documented in this file.

### PENDING RELEASE (TBD)

- Add ability to elevate a user to super_user or sys_admin programatically.

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
