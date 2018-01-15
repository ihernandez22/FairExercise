class TransactionsController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    status, errors, response = API::SUCCESS, Array.new, Hash.new
    @credit_card = CreditCard.find_by_id(params[:credit_card_id])
    if @credit_card
      @transaction = @credit_card.transactions.create(transaction_params)
      if @transaction.valid?
        response = @transaction
      else
        p @transaction.inspect
        p @transaction.errors.inspect
        status = API::FAIL
        @transaction.errors.messages.each { |k,v| errors.push("#{k.to_s.gsub("_", " ").titlecase}: #{v}.") }
      end
    else
      status = API::FAIL
      errors.push("The credit card with id \"#{params[:credit_card_id]} does not exist.")
    end
    render json: {
      status: status,
      errors: errors,
      response: response
    }
  end

private

  def transaction_params
    params.require(:transaction).permit(:date, :transaction_type, :amount, :credit_card_id)
  end

end
