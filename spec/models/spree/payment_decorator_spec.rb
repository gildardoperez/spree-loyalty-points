require "spec_helper"
require "models/concerns/spree/loyalty_points_spec"
require "models/concerns/spree/payment/loyalty_points_spec"

#TODO -> rspecs missing
describe Spree::Payment do

  before(:each) do
    @payment = create(:payment_with_loyalty_points)
  end

  it "should include notify_paid_order in state_machine after callbacks" do
    Spree::Payment.state_machine.callbacks[:after].map { |callback| callback.instance_variable_get(:@methods) }.include?([:notify_paid_order]).should be_true
  end

  it "should include redeem_loyalty_points in state_machine after callbacks" do
    Spree::Payment.state_machine.callbacks[:after].map { |callback| callback.instance_variable_get(:@methods) }.include?([:redeem_loyalty_points]).should be_true
  end

  it "should include return_loyalty_points in state_machine after callbacks" do
    Spree::Payment.state_machine.callbacks[:after].map { |callback| callback.instance_variable_get(:@methods) }.include?([:return_loyalty_points]).should be_true
  end

  describe 'notify_paid_order' do

    context "all payments completed" do

      before :each do
        @payment.stub(:all_payments_completed?).and_return(true)
      end

      it "should change paid_at in order" do
        expect {
          @payment.send(:notify_paid_order)
        }.to change{ @payment.order.paid_at }
      end

    end

    context "all payments not completed" do

      before :each do
        @payment.stub(:all_payments_completed?).and_return(false)
      end

      it "should change paid_at in order" do
        expect {
          @payment.send(:notify_paid_order)
        }.to_not change{ @payment.order.paid_at }
      end

    end

  end

  #TODO -> Test state_not scope separately.
  describe 'state_not' do

    let (:payment1) { create(:payment_with_loyalty_points, state: 'checkout') }
    let (:payment2) { create(:payment_with_loyalty_points, state: 'pending') }

    before :each do
      Spree::Payment.destroy_all
    end

    it "should return payments where state is not complete when complete is passed" do
      Spree::Payment.state_not('checkout').should eq([payment2])
    end

    it "should return payments where state is not pending when pending is passed" do
      Spree::Payment.state_not('pending').should eq([payment1])
    end

  end

  describe 'all_payments_completed?' do

    let (:payments) { create_list(:payment_with_loyalty_points, 5, state: "completed") }

    context "all payments complete" do

      before :each do
        order = create(:order_with_loyalty_points)
        @payment.order = order
        order.payments = payments
      end

      it "should return true" do
        @payment.send(:all_payments_completed?).should eq(true)
      end

    end

    context "one of the payments incomplete" do

      before :each do
        order = create(:order_with_loyalty_points)
        @payment.order = order
        payments.first.state = "void"
        order.payments = payments
      end

      it "should return false" do
        @payment.send(:all_payments_completed?).should eq(false)
      end

    end

  end

  describe 'invalidate_old_payments' do

    let (:payments) { create_list(:payment_with_loyalty_points, 5, state: "checkout") }

    before :each do
      order = create(:order_with_loyalty_points)
      @payment.order = order
      order.payments = payments + [@payment]
      order.payments.stub(:with_state).with('checkout').and_return(order.payments)
      order.payments.stub(:where).and_return(order.payments)
    end

    context "when payment not by loyalty points" do

      before :each do
        @payment.stub(:by_loyalty_points?).and_return(false)
      end

      it "should receive with_state on order.payments" do
        @payment.order.payments.should_receive(:with_state).with('checkout')
        @payment.send(:invalidate_old_payments)
      end

      it "should receive where on order.payments" do
        @payment.order.payments.should_receive(:where)
        @payment.send(:invalidate_old_payments)
      end

      #TODO -> Check only loyalty_points payments should invalidate.
      it "should receive invalidate" do
        @payment.should_receive(:invalidate!)
        @payment.send(:invalidate_old_payments)
      end

    end

    context "when payment by loyalty points" do

      before :each do
        @payment.stub(:by_loyalty_points?).and_return(true)
      end

      it "should not receive with_state on order.payments" do
        @payment.order.payments.should_not_receive(:with_state)
        @payment.send(:invalidate_old_payments)
      end

    end

  end

  it_should_behave_like "LoyaltyPoints" do
    let(:resource_instance) { @payment }
  end

  it_should_behave_like "Payment::LoyaltyPoints" do
    let(:resource_instance) { @payment }
  end

  describe 'by_loyalty_points' do

    let(:loyalty_points_payment_method) { Spree::PaymentMethod::LoyaltyPoints.create!(:environment => Rails.env, :active => true, :name => 'LoyaltyPoints') }
    let(:check_payment_method) { Spree::PaymentMethod::Check.create!(:environment => Rails.env, :active => true, :name => 'Check') }
    let (:payment1) { create(:payment_with_loyalty_points, payment_method: loyalty_points_payment_method) }
    let (:payment2) { create(:payment_with_loyalty_points, payment_method: check_payment_method) }

    #TODO -> Check actual query of database(i.e. actual fetching of records).
    it "should return payments with loyalty_points payment method" do
      Spree::Payment.by_loyalty_points.should eq([payment1])
    end

  end

end
