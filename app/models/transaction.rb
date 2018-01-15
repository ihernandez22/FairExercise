class Transaction < ApplicationRecord
  # NOTE: I thought about creating subclasses for the different types
  #       But the functionality doesn't differ much between types
  TRANSACTION_TYPE_DRAW = "DRAW"
  TRANSACTION_TYPE_PAYMENT = "PAYMENT"
  TRANSACTION_TYPE_INTEREST = "INTEREST"
  TRANSACTION_TYPES = [TRANSACTION_TYPE_DRAW, TRANSACTION_TYPE_PAYMENT, TRANSACTION_TYPE_INTEREST]
  TRANSACTION_USER_SELECTABLE = TRANSACTION_TYPES - [TRANSACTION_TYPE_INTEREST]
  TRANSACTION_MINUS_BALANCE = [TRANSACTION_TYPE_PAYMENT]
  TRANSACTION_PLUS_BALANCE = TRANSACTION_TYPES - TRANSACTION_MINUS_BALANCE
  DATE_FORMAT = "%m/%d/%Y"
  
  belongs_to :credit_card
  validate :check_credit_limit
  validates :date, presence: true
  validates :transaction_type, presence: true, inclusion: { in: TRANSACTION_TYPES }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :credit_card_id, presence: true
  validates :credit_card, presence: true
  
  def net_amount
    (transaction_type.in? TRANSACTION_MINUS_BALANCE) ? -(amount) : amount
  end

  def to_json_hash
    {
      transaction: {
        date: date.strftime(DATE_FORMAT),
        transaction_type: transaction_type,
        amount: amount,
        credit_card_id: "#{credit_card_id}"
      }
    }
  end

private
  
  def check_credit_limit
    if id.nil? && transaction_type == TRANSACTION_TYPE_DRAW && credit_card &&
        amount && (credit_card.balance + amount) > CreditCard::CREDIT_LIMIT
      errors.add (:amount), "this transaction will put the credit card over the credit limit"
      throw :abort
    end
  end

end
