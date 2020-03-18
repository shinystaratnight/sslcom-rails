shared_examples_for 'it has roles' do
  subject { described_class.new }

  context 'is_role?' do
    it { should respond_to :has_role? }
    it { should respond_to :is_admin? }
    it { should respond_to :is_super_user? }
    it { should respond_to :is_ra_admin? }
    it { should respond_to :is_owner? }
    it { should respond_to :is_account_admin? }
    it { should respond_to :is_standard? }
    it { should respond_to :is_reseller? }
    it { should respond_to :is_billing? }
    it { should respond_to :is_billing_only? }
    it { should respond_to :is_installer? }
    it { should respond_to :is_validations? }
    it { should respond_to :is_validations_only? }
    it { should respond_to :is_validations_and_billing_only? }
    it { should respond_to :is_individual_certificate? }
    it { should respond_to :is_individual_certificate_only? }
    it { should respond_to :is_users_manager? }
    it { should respond_to :is_affiliate? }
    it { should respond_to :is_system_admins? }
  end
end
