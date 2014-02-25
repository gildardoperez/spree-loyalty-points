require "spec_helper"

describe Spree::LoyaltyPointsDebitTransaction do

  before(:each) do
    @loyalty_points_debit_transaction = build(:loyalty_points_debit_transaction)
  end

  it "is valid with valid attributes" do
    @loyalty_points_debit_transaction.should be_valid
  end

  describe 'update_user_balance' do

    it "should decrement user's loyalty_points_balance" do
      expect {
        @loyalty_points_debit_transaction.send(:update_user_balance)
      }.to change{ @loyalty_points_debit_transaction.user.loyalty_points_balance }.by(-@loyalty_points_debit_transaction.loyalty_points)
    end

  end

  describe 'update_balance' do

    before :each do
      @user_balance = 300
      @loyalty_points_debit_transaction.user.stub(:loyalty_points_balance).and_return(@user_balance)
      @loyalty_points_debit_transaction.send(:update_balance)
    end

    it "should set balance" do
      @loyalty_points_debit_transaction.balance.should eq(@user_balance - @loyalty_points_debit_transaction.loyalty_points)
    end

  end

  describe 'transaction_type' do

    before :each do
      @loyalty_points_debit_transaction = FactoryGirl.build(:loyalty_points_debit_transaction)
    end

    it "should be Debit" do
      @loyalty_points_debit_transaction.transaction_type.should eq('Debit')
    end

  end

end
