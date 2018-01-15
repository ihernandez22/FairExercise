require 'test_helper'

class TransactionsControllerTest < ActionDispatch::IntegrationTest

	def setup
  	@credit_card = credit_cards(:credit_card)
    @params = {
      transaction: {
        date: Date.today.strftime("%m-%d-%Y"),
        transaction_type: Transaction::TRANSACTION_TYPE_DRAW,
        amount: CreditCard::CREDIT_LIMIT/2,
        credit_card_id: @credit_card.id
      }
    }
  end
  
	test "should create transaction" do
  	assert_difference "Transaction.count", 1 do
    	post "#{credit_cards_path}/#{@credit_card.id}/transactions", params: @params
    end
  end
end
