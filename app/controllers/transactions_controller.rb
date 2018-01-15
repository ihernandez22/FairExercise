class TransactionsController < ApplicationController
  protect_from_forgery with: :null_session

  def new
    @credit_card = CreditCard.find(params[:credit_card_id])
    @transaction = @credit_card.transactions.new
  end

  def create
    @credit_card = CreditCard.find_by_id(params[:credit_card_id])
    respond_to do |format|
      format.js {
        @transaction = @credit_card.transactions.create(transaction_params)
        render layout: false
      }
      format.json {
        status, errors, response = API::SUCCESS, Array.new, Hash.new
        if transaction_params[:transaction_type] == Transaction::TRANSACTION_TYPE_INTEREST
          status = API::FAIL
          errors.push("Only the system is allowed to create INTEREST charges.")
        else
          if @credit_card
            @transaction = @credit_card.transactions.create(transaction_params)
            if @transaction.valid?
              response = @transaction
            else
              status = API::FAIL
              @transaction.errors.messages.each do |k,v|
                v.each do |e|
                  errors.push("#{k.to_s.gsub("_", " ").titlecase}: #{e}.")
                end
              end
            end
          else
            status = API::FAIL
            errors.push("The credit card with id \"#{params[:credit_card_id]} does not exist.")
          end
        end
        render json: {
          status: status,
          errors: errors,
          response: response
        }
      }
    end
  end

private

  def transaction_params
    params.require(:transaction).permit(:date, :transaction_type, :amount, :credit_card_id)
  end

end
