class CreditCard < ApplicationRecord 
  CREDIT_LIMIT = 1000
  INTEREST_RATE = 0.35
  DATE_FORMAT = "%m/%d/%Y"

  has_many :transactions, dependent: :destroy
  validates :name, presence: true, uniqueness: true
  validates :current_payment_period_start_date, presence: true

  def current_payment_period_end_date
    current_payment_period_start_date + 29.days
  end

  def balance(at_date = Date.today)
    bal = 0
    transactions.order(:date).where("date <= ?", at_date).each { |t| bal += t.net_amount }
    bal
  end

  def close_payment_period
    status = true
    message = ""
    interest_transaction = nil
    if (Date.today - 29.days) >= current_payment_period_start_date
      interest_transaction = create_interest_charge
      message = "The payment period has been closed and ";
      if interest_transaction
        message += "an interest charge for $#{interest_transaction.amount} has been created."
      else
        message += "no interest was charged."
      end
      update_attribute(:current_payment_period_start_date, current_payment_period_start_date + 30.days)
    else
      status = false
      message = "This action could not be completed. The credit card's payment period has not ended. The payment period may only be closed on or after #{current_payment_period_end_date.strftime("%M/%D/%Y")}."
    end
    {
      status: status ? API::SUCCESS : API::FAIL,
      message: message,
      interest_transaction: interest_transaction
    }
  end

  def to_json_hash
    ts_arr = Array.new
    transactions.order(:date).each { |t| ts_arr.push(t.to_json_hash[:transaction]) }
    {
      credit_card: {
        id: id,
        name: name,
        current_payment_period_start_date: current_payment_period_start_date.strftime(DATE_FORMAT),
        current_payment_period_end_date: current_payment_period_end_date.strftime(DATE_FORMAT),
        current_balance: balance,
        transactions: ts_arr
      }
    }
  end

private

  def create_interest_charge
    interest_bal = 0
    ts = transactions.order(:date).where("date >= ? AND date <= ?", current_payment_period_start_date, current_payment_period_end_date)
    bal = balance(current_payment_period_start_date - 1.day)
    return nil if ts.empty? && bal <= 0
    prev_bal, prev_bal_date = bal, current_payment_period_start_date - 1.days
    ts.each do |t|
      bal += t.net_amount
      if prev_bal_date < t.date
        interest_bal += ([prev_bal,0].max * INTEREST_RATE / 365 * (t.date - prev_bal_date).to_i)
        prev_bal, prev_bal_date = bal, t.date
      end
    end
    interest_bal += ([prev_bal,0].max * INTEREST_RATE / 365 * (current_payment_period_end_date - prev_bal_date).to_i)
    transactions.create(date: Date.today, transaction_type: Transaction::TRANSACTION_TYPE_INTEREST, amount: interest_bal.round(2))
  end

end
