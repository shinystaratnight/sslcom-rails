shared_examples_for 'it has roles' do
  subject { described_class.new }

  context 'is_role?' do
    it { is_expected.to respond_to :has_role? }
    it { is_expected.to respond_to :is_admin? }
    it { is_expected.to respond_to :is_super_user? }
    it { is_expected.to respond_to :is_ra_admin? }
    it { is_expected.to respond_to :is_owner? }
    it { is_expected.to respond_to :is_account_admin? }
    it { is_expected.to respond_to :is_standard? }
    it { is_expected.to respond_to :is_reseller? }
    it { is_expected.to respond_to :is_billing? }
    it { is_expected.to respond_to :is_billing_only? }
    it { is_expected.to respond_to :is_installer? }
    it { is_expected.to respond_to :is_validations? }
    it { is_expected.to respond_to :is_validations_only? }
    it { is_expected.to respond_to :is_validations_and_billing_only? }
    it { is_expected.to respond_to :is_individual_certificate? }
    it { is_expected.to respond_to :is_individual_certificate_only? }
    it { is_expected.to respond_to :is_users_manager? }
    it { is_expected.to respond_to :is_affiliate? }
    it { is_expected.to respond_to :is_system_admins? }
  end
end
