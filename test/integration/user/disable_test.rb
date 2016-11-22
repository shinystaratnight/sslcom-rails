require 'test_helper'

describe 'Disable user' do
  before do
    initialize_roles

  end

  describe 'by sysadmin user' do
    describe 'CANNOT access' do
      it 'their own account' do

      end
        
      it 'other associated accounts' do
        
      end
    end
  end

  describe 'by account_admin' do
    describe 'CANNOT access' do
      it 'account_admins account' do

      end
    end
    describe 'CAN access' do
      it 'their own account' do
      end

      it 'other associated accounts' do
        
      end
    end
  end

  describe 'other users on disabled users account' do
    it 'CANNOT access the disabled users account' do

    end
    it 'CAN access other accounts' do
      
    end
  end

end
