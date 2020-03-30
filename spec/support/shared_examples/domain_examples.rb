shared_examples_for 'it filters on domain' do
  subject { create(:"#{described_class.name.underscore}") }

  describe '#search_domains' do
    it "find #{described_class} with a given domain" do
      expect(described_class.search_domains(subject.name)).to include(subject)
    end

    it "find #{described_class} with a given email" do
      expect(described_class.search_domains(subject.email)).to include(subject)
    end

    it "find #{described_class} with a given email host" do
      expect(described_class.search_domains(subject.email.split('@').last)).to include(subject)
    end
  end
end
