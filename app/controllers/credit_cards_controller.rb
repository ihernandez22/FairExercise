class CreditCardsController < ApplicationController
  protect_from_forgery with: :null_session

  def index
    @credit_cards = CreditCard.all.order(:name)
  end

  def new
    @credit_card = CreditCard.new
  end

  def create
    @credit_card = CreditCard.create(credit_card_params)
    respond_to do |format|
      format.js { render layout: false }
      format.json {
        status, errors = API::SUCCESS, Array.new
        p "HERE"
        unless @credit_card.valid?
          status = API::FAIL
          @credit_card.errors.messages.each do |k, v|
            v.each do |e|
              errors.push("#{k.to_s.gsub("_", " ").titlecase}: #{e}.")
            end
          end
        end
        render json: {
          status: status,
          errors: errors,
          response: status == API::SUCCESS ? @credit_card.to_json_hash : Hash.new
        }
      }
    end
  end

  def show
    @credit_card = CreditCard.find_by_id(params[:id])
    respond_to do |format|
      format.html
      format.json {
        status, errors, response = API::SUCCESS, Array.new, Hash.new
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
      }
    end
  end

  def close_payment_period
    @credit_card = CreditCard.find_by_id(params[:id])
    respond_to do |format|
      format.js {
        @cpp = @credit_card.close_payment_period
        render layout: false
      }
      format.json {
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
      }
    end
  end

private

  def credit_card_params
    params.require(:credit_card).permit(:name, :current_payment_period_start_date)
  end

end
