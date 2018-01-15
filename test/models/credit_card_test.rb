require 'test_helper'

class CreditCardTest < ActiveSupport::TestCase

  # BEGIN VALIDATIONS TESTING
  test "should be valid credit card" do
    credit_card = credit_cards(:credit_card)
    assert credit_card.valid?
  end

  test "should be invalid credit card due to blank name" do
    credit_card = credit_cards(:credit_card)
    credit_card.name = ""
    assert_not credit_card.valid?
  end

  test "should be invalid credit card due to duplicate name" do
    credit_card = credit_cards(:credit_card)
    credit_card_2 = CreditCard.new(name: "James") 
    assert_not credit_card_2.valid?
  end
  
  test "should be invalid credit card due to missing start date" do
    credit_card = credit_cards(:credit_card)
    credit_card.current_payment_period_start_date = nil
    assert credit_card.valid? && credit_card.current_payment_period_start_date == Date.today
  end

  test "should be invalid due to the amount causing credit card to go over limit" do
    credit_card = credit_cards(:credit_card)
    assert_no_difference "Transaction.count" do
      t = credit_card.transactions.create(date: Date.today, transaction_type: Transaction::TRANSACTION_TYPE_DRAW, amount: CreditCard::CREDIT_LIMIT*2)
    end
  end
  # END VALIDATIONS TESTING
  # BEGIN BALANCE_TESTING
  test "balance should return 500" do
    test_case_1199 = credit_cards(:test_case_1199)
    assert test_case_1199.balance(30.days.ago) == 500.0
  end

  test "balance should return 300" do
    test_case_1199 = credit_cards(:test_case_1199)
    assert test_case_1199.balance(15.days.ago) == 300.0
  end

  test "balance should return 400" do
    test_case_1199 = credit_cards(:test_case_1199)
    assert test_case_1199.balance(5.days.ago) == 400.0
  end

  test "balance should return negative amount" do
    test_case_surplus = credit_cards(:test_case_surplus)
    assert test_case_surplus.balance < 0
  end

  test "balance should return 0" do
    test_case_even = credit_cards(:test_case_even)
    assert test_case_even.balance == 0.0
  end
  # END BALANCE_TESTING
  # BEGIN CLOSE_PAYMENT_PERIOD TESTING
  test "interest rate should not have changed" do
    # NOTE: Some of the following test cases are based off the built in value CreditCard::INTEREST_RATE
    #       So we first assert that the value hasn't changed
    assert CreditCard::INTEREST_RATE == 0.35
  end

  test "should create an interest charge of $14.38" do
    test_case_1438 = credit_cards(:test_case_1438)
    response = test_case_1438.close_payment_period
    assert response[:status] == API::SUCCESS && response[:interest_transaction] && response[:interest_transaction].amount == 14.38 && test_case_1438.balance == 514.38
  end

  test "should create an interest charge of $11.99" do
    test_case_1199 = credit_cards(:test_case_1199)
    p test_case_1199.inspect
    response = test_case_1199.close_payment_period
    assert response[:status] == API::SUCCESS && response[:interest_transaction] && response[:interest_transaction].amount == 11.99 && test_case_1199.balance == 411.99
  end 

  test "should not create an interest charge due to surplus" do
    test_case_surplus = credit_cards(:test_case_surplus)
    response = test_case_surplus.close_payment_period
    assert response[:status] == API::SUCCESS && response[:interest_transaction].nil? && test_case_surplus.balance == (CreditCard::CREDIT_LIMIT*-2)
  end

  test "should not create an interest charge due to even balance" do
    test_case_even = credit_cards(:test_case_even)
    response = test_case_even.close_payment_period
    assert response[:status] == API::SUCCESS && response[:interest_tranasction].nil? && test_case_even.balance == 0
  end

  test "should create an interest charge of $9.11 (surplus in middle of period test)" do
    test_case_911_surplus = credit_cards(:test_case_911_surplus)
    response = test_case_911_surplus.close_payment_period
    assert response[:status] == API::SUCCESS && response[:interest_transaction].amount == 9.11 && test_case_911_surplus.balance == 409.11
  end

	test "should create an interest charge of $9.11 (even balance in middle period test)" do
	  test_case_911_even = credit_cards(:test_case_911_even)
    response = test_case_911_even.close_payment_period
    assert response[:status] == API::SUCCESS && response[:interest_transaction].amount = 9.11 && test_case_911_even.balance == 409.11
  end

  test "should move the current_period_payment_start_date up by 30 days" do
    test_case_1438 = credit_cards(:test_case_1438)
    prev_start_date = test_case_1438.current_payment_period_start_date
    response = test_case_1438.close_payment_period
    assert (test_case_1438.current_payment_period_start_date - prev_start_date).to_i == 30
  end

  test "should not create an interest charge because it is not the payment period end date" do
    test_case_not_end_date = credit_cards(:test_case_not_end_date)
    response = test_case_not_end_date.close_payment_period
    assert response[:status] == API::FAIL
  end
  # END CLOSE_PAYMENT_PERIOD TESTING
  # BEGIN TO_JSON_HASH TESTING
  test "should return hash for json response" do
    test_case_1199 = credit_cards(:test_case_1199)
    test_case_1199.close_payment_period
    json_hash = test_case_1199.to_json_hash
    checks = true
    if json_hash[:credit_card] && json_hash[:credit_card][:transactions]
      checks &&= json_hash[:credit_card][:name] == "TestCase1199"
      checks &&= json_hash[:credit_card][:current_payment_period_start_date] == (30.days.ago).strftime(CreditCard::DATE_FORMAT)
      checks &&= json_hash[:credit_card][:current_payment_period_end_date] == (Date.today).strftime(CreditCard::DATE_FORMAT)
      checks &&= json_hash[:credit_card][:current_balance] == 411.99
      checks &&= json_hash[:credit_card][:transactions].count == 4
      checks &&= json_hash[:credit_card][:transactions][0][:amount] == 500.0
      checks &&= json_hash[:credit_card][:transactions][3][:amount] == 11.99
    else
      checks = false;
    end
    assert checks
  end
  # END TO_JSON_OBJECT TESTING
end
