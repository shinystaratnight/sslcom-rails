# frozen_string_literal: true

user = FactoryBot.create(:user, email: 'superuser1@ssl.com', login: 'superuser1')
role = Role.find_or_create_by(name: 'super_user')
FactoryBot.create(:assignment, user: user, role: role, ssl_account: user.ssl_account)
