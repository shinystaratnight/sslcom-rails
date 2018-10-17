#
# Populate main roles descriptions
#
namespace :roles do
  desc "Create or update roles"
  task populate: :environment do
    Role.find_or_initialize_by(name: 'billing').update_attributes(
        description: 'Access to billing tasks for team. Tasks include creating or deleting billing profiles, managing transactions and renewing certificate orders.'
    )
    Role.find_or_initialize_by(name: 'users_manager').update_attributes(
        description: "Manage teams' users. Tasks include inviting users to team, removing, editing roles, disabling and enabling teams' users."
    )
    Role.find_or_initialize_by(name: 'installer').update_attributes(
        description: "Access to completed certificate and site seal, also has the ability to submit initial CSR and rekey/reprocess the certificate."
    )
    Role.find_or_initialize_by(name: 'validations').update_attributes(
        description: "Access to validation tasks for the Team. Tasks include uploading validation documents, selecting the validation method, and other related tasks."
    )
    Role.find_or_initialize_by(name: 'account_admin').update_attributes(
        description: "Access to all tasks related to managing entire account and team except altering user who owns the ssl team."
    )
    Role.find_or_initialize_by(name: 'owner').update_attributes(
        description: "Access to all tasks related to managing entire account and team including transferring ownership of the team."
    )
    Role.find_or_initialize_by(name: 'super_user').update_attributes(
        description: "All permissions to everything."
    )
    Role.find_or_initialize_by(name: 'ra_admin').update_attributes(
        description: "Can manage RA system settings like product configurations and mappings."
    )
    Role.find_or_initialize_by(name: 'sysadmin').update_attributes(
        description: "Permissions to everything except SSL.com CA."
    )
    Role.find_or_initialize_by(name: 'affiliate').update_attributes(
        description: "Affiliate."
    )
    Role.find_or_initialize_by(name: 'reseller').update_attributes(
        description: "Reseller."
    )
    Role.find_or_initialize_by(name: 'individual_certificate').update_attributes(
        description: "Access to only certificate orders assigned to this user in a given team."
    )
  end
end

