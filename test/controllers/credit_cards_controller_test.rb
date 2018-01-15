require 'test_helper'

class CreditCardsControllerTest < ActionDispatch::IntegrationTest
	def setup
		@params = {
      credit_card: {
    		name: "Credit Card #{DateTime.now.strftime('%Q')}",
	      current_payment_period_start_date: 29.days.ago
      }
  	}
  end

	test "should create a credit card" do
 		assert_difference "CreditCard.count", 1 do
	 		post "#{credit_cards_path}", params: @params
  	end
  end
 	test "should get a credit card" do
    credit_card = credit_cards(:credit_card)
    get "#{credit_cards_path}/#{credit_card.id}"
    assert_response :success
  end

  test "should create an interest transaction" do
    credit_card = credit_cards(:test_case_1199)
    assert_difference "Transaction.count", 1 do
      post "#{credit_cards_path}/#{credit_card.id}/close_payment_period"
    end
  end
end
