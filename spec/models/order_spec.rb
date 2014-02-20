require 'spec_helper'

describe Order do
  let(:order) { create(:order) }
  let(:product) { create(:product, cost_in_cents: 100000) }

  describe 'adding a product to the order' do
    it 'increases the total cost of the order' do
      expect {
        order.products << product
      }.to change { order.total_cost_in_cents }.by(product.cost_in_cents)
    end
  end

  describe 'total cost in cents' do
    it 'is the sum of all the products on the order' do
      product2 = create(:product, cost_in_cents: 50000)
      order.products << product << product2
      expect(order.total_cost_in_cents).to eq (product2.cost_in_cents + product.cost_in_cents)
    end
  end

  describe 'new orders' do
    it 'starts off in the unsubmitted state' do
      order = create(:order)

      expect(order.unsubmitted?).to eq true
    end
  end

  describe 'submitting an order' do
    it 'transitions to the processing state' do
      order = create(:order)
      order.submit!
      expect(order.processing?).to eq true
    end
  end

  describe 'shipping an order' do
    it 'transitions to the shipped state' do
      order = create(:order, aasm_state: 'processing')
      order.ship!
      expect(order.shipped?).to eq true
    end
  end

  describe "adding a product to an order" do
    context 'with remaining stock' do
      let(:product) { create(:product, amount_in_stock: 5) }

      before do
        order.products << product
      end

      it 'adds the product to the order' do
        expect(order.products).to include product
      end

      it 'decrements the amount of product in stock' do
        expect(product.amount_in_stock).to eq 4
      end
    end

    context 'with no remaining stock' do
      let(:product) { create(:product, amount_in_stock: 0) }

      before do
        expect { product.orders << order }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'does not add the product to the order' do
        expect(order.products).to_not include product
      end

      it 'does not decrement the amount of product in stock' do
        product.reload
        expect(product.amount_in_stock).to eq 0
      end
    end
  end
end
