shared_examples_for 'an ApplicationDecorator' do
  subject { create(:"#{described_class.name.underscore}") }

  describe 'pagination' do
    it 'uses PaginationDecorator' do
      expect(described_class.collection_decorator_class).to eq(PaginatingDecorator)
    end
  end
end
