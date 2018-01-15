class CreditCardsController < ApplicationController
  protect_from_forgery with: :null_session

  def show
    status, errors, response = API::SUCCESS, Array.new, Hash.new
    @credit_card = CreditCard.find_by_id(params[:id])
    if @credit_card.nil?
      status = API::FAIL
      errors.push("The credit card with id \"#{params[:id]} does not exist.")
    else
      response = @credit_card.to_json_hash
    end
    render json: {
      status: status,
      errors: errors,
      response: response
    }
  end

  def create
    @credit_card = CreditCard.create(credit_card_params)
    status, errors = API::SUCCESS, Array.new
    unless @credit_card.valid?
      status = API::FAIL
      @credit_card.errors.messages { |k, v| errors.push("#{k.to_s.gsub("_", " ").titlecase}: #{v}.") }
    end
    render json: {
      status: status,
      errors: errors,
      response: status ? @credit_card.to_json_hash : Hash.new
    }
  end

  def close_payment_period
    @credit_card = CreditCard.find_by_id(params[:id])
    status, errors, response = API::SUCCESS, Array.new, Hash.new
    if @credit_card
      cpp = @credit_card.close_payment_period
      status, errors = API::SUCCESS, [cpp[:message]] if cpp[:status] == API::FAIL
      response.merge!(@credit_card.to_json_hash)
      response.merge!(cpp[:interest_transaction].to_json_hash) if cpp[:interest_transaction]
    else
      status = API::FAIL
      errors.push("The credit card with id \"#{params[:id]} does not exist.")
    end
    render json: {
      status: status,
      errors: errors,
      response: response
    }
  end

private

  def credit_card_params
    params.require(:credit_card).permit(:name, :current_payment_period_start_date)
  end

end
