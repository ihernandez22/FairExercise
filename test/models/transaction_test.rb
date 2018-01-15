require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  def setup
    @credit_card = credit_cards(:credit_card)
    @transaction = @credit_card.transactions.first
  end
  
  # BEGIN VLIDATIONS TESTING
  test "should be valid draw transaction" do
    assert @transaction.valid?
  end

  test "should not be valid transaction without date" do
    @transaction.date = nil
    assert_not @transaction.valid? 
  end

  test "should be valid payment transaction" do
    @transaction.transaction_type = Transaction::TRANSACTION_TYPE_PAYMENT
    assert @transaction.valid?
  end

  test "should be valid interest transaction" do
    @transaction.transaction_type = Transaction::TRANSACTION_TYPE_INTEREST
    assert @transaction.valid?
  end

  test "should not be valid transaction due to missing type" do
    @transaction.transaction_type = nil
    assert_not @transaction.valid?
  end

  test "should not be valid transaction due to invalid type" do
    @transaction.transaction_type = "SOMETHING ELSE"
    assert_not @transaction.valid?
  end

  test "should not be valid due to missing amount" do
    @transaction.amount = nil
    assert_not @transaction.valid?
  end

  test "should not be valid due to invalid amount" do
    @transaction.amount = "abc"
    assert_not @transaction.valid?
  end

  test "should not be valid due to missing credit card id" do
    @transaction.credit_card_id = nil
    assert_not @transaction.valid?
  end
  # END VALIDATIONS TESTING
  # BEGIN TO_JSON_HASH TESTING
  test "should return correct json hash for transaction" do
    json_hash = @transaction.to_json_hash
    checks = true
    p json_hash.inspect
    if json_hash[:transaction]
      checks &&= json_hash[:transaction][:date] == (31.days.ago).strftime(Transaction::DATE_FORMAT)
      checks &&= json_hash[:transaction][:transaction_type] == Transaction::TRANSACTION_TYPE_DRAW
      checks &&= json_hash[:transaction][:amount] == CreditCard::CREDIT_LIMIT/2
      checks &&= json_hash[:transaction][:credit_card_id] == "#{@transaction.credit_card_id}"
    else
      checks = false
    end
    assert checks
  end
  # END TO_JSON_HASH TESTING

end
