require 'rails_helper'
describe Csr do
  describe '.is_reject_key?' do
    context 'debian weak keys' do
      context 'blacklist-openssl' do
        it 'is rejected (2048)' do
          csr = create(:csr, :body_2048)
          weak_key = create(:weak_key, :bit_2048)
          Digest::SHA1.stubs(:hexdigest).with("Modulus=#{csr.public_key.n.to_s(16)}\n").returns('a' * 20 + weak_key.fingerprint)
          expect(csr.is_reject_key?).to eq true
        end

        it 'is rejected (4096)' do
          csr = create(:csr, :body_4096)
          weak_key = create(:weak_key, :bit_4096)
          Digest::SHA1.stubs(:hexdigest).with("Modulus=#{csr.public_key.n.to_s(16)}\n").returns('a' * 20 + weak_key.fingerprint)
          expect(csr.is_reject_key?).to eq true
        end

        it 'is not rejected' do
          csr = create(:csr)
          create_list(:weak_key, 3, :bit_2048)
          create_list(:weak_key, 3, :bit_4096)
          expect(csr.is_reject_key?).to eq false
        end
      end
    end

    context 'compromised keys' do
      it 'is rejected (2048)' do
        csr = create(:csr, :body_2048)
        compromised_key = create(:compromised_key, :bit_2048)
        Digest::SHA1.stubs(:hexdigest).with("Modulus=#{csr.public_key.n.to_s(16)}\n").returns('a' * 20 + compromised_key.fingerprint)
        expect(csr.is_reject_key?).to eq true
      end

      it 'is rejected (4096)' do
        csr = create(:csr, :body_4096)
        compromised_key = create(:compromised_key, :bit_4096)
        Digest::SHA1.stubs(:hexdigest).with("Modulus=#{csr.public_key.n.to_s(16)}\n").returns('a' * 20 + compromised_key.fingerprint)
        expect(csr.is_reject_key?).to eq true
      end

      it 'is not rejected' do
        csr = create(:csr)
        create_list(:compromised_key, 3, :bit_2048)
        create_list(:compromised_key, 3, :bit_4096)
        expect(csr.is_reject_key?).to eq false
      end
    end
  end
end
