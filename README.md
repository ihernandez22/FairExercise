# Fair Exercise
Author: Isaac Hernandez

This is Isaac Hernandez's response to Fair.com's interview technical question. This README will explain the JSON API and how to use it. Towards the bottom there will be a big chunk of code that can be copied and pasted into a Rails console to implement the two test cases from the [spec](https://github.com/wearefair/interview/tree/master/engineering). That chunk of code communicates with my Heroku app, but if you want to test it locally, you will have to replace all of the Heroku app url's with `localhost:port`. Some of these links respond to both JavaScript and JSON requests or HTML and JSON requests, so it may be necessary to specify the format for the request (the chunk of code does that already).

As mentioned above, the site is deployed to Heroku and has a much simpler user interface if you prefer to use that: [Heroku App](https://isaac-hernandez-fair-exercise.herokuapp.com).

## JSON API Specification

`[POST] "credit_cards"` - For creating a credit card. You must save the credit card's id to use it.
```
  Parameters: {
    name: STRING (REQUIRED and must be UNIQUE),
    current_payment_period_start_date: STRING (REQUIRED and must be in format "DD/MM/YYYY")
  }

  Response: {
    "status": STRING (either "success" or "fail"),
    "errors": ARRAY of STRINGS (each STRING is an error that occurred),
    "response": HASH TABLE (which is either empty on fail or contains a CREDIT_CARD Object)
  }
```

`[GET] "credit_cards/[:id]"` - For getting the information of an existing credit card. No parameters are necessary as the ID is in the endpoint.
```
  Parameters: {}
  Response: {
    "status": STRING (either "success" or "fail"),
    "errors": ARRAY of STRINGS (each STRING is an error that occurred),
    "response": HASH TABLE (which is either empty on fail or contains a CREDIT_CARD Object)
  }
```

`[POST] "credit_cards/[:id]/transactions"` - For creating a transaction under a given credit card.
```
  Parameters: {
    date: STRING (REQUIRED and must be in format "DD/MM/YYYY"),
    transaction_type: STRING (REQUIRED and must be DRAW or PAYMENT),
    amount: FLOAT (REQUIRED and must be a NUMBER and GREATER THAN 0)
  }
  Response: { (JSON OBJECT)
    "status": STRING (either "success" or "fail"),
    "errors": ARRAY of STRINGS (each STRING is an error that occurred),
    "response": HASH TABLE (which is either empty on fail or contains a TRANSACTION Object)
  }
```

`"credit_cards/[:id]/close_payment_period"` - For closing a payment period. This will create an interest charge, if applicable, and move the credit card on to the next payment period.
```
  Parameters: {} (NONE, since the ID of the credit card is in the endpoint)
  Response: { (JSON OBJECT)
    "status": STRING (either "success" or "fail"),
    "errors": ARRAY of STRINGS (each STRING is an error that occurred),
    "response": HASH TABLE (which is either empty on fail, or contains a CREDIT_CARD object and may contain TRANSACTION Object of the interest charge if one was created)
  }
```


Objects returned in the JSON responses:

`CREDIT_CARD` Object
```
    "credit_card": {
      "name": STRING,
      "current_payment_period_start_date": STRING (of DATE, in format "DD/MM/YYYY"),
      "current_payment_period_end_date": STRING (of DATE, in format "DD/MM/YYYY"),
      "current_balance": FLOAT,
      "transactions": ARRAY (of TRANSACTION Objects)
    }
```
`TRANSACTION` Object
```
    "transaction": {
      "date": STRING (of DATE, in format "DD/MM/YYYY"),
      "transaction_type": STRING (either DRAW, PAYMENT, or INTEREST)
      "amount": FLOAT,
      "credit_card_id": STRING (of ID number)
    }
```

Here is the code that can be copied and pasted to a Rails console. Just be aware that the names for the credit cards will be strings of time signatures. Also, note that the test cases in the spec specify that there is a draw on day 1 of the payment period but that leads to faulty logic (because then it should be applied for 29 days instead of 30). Those draws will be initial balances made the day before the payment period so that they are applied for the full 30 days just like they are in the formulas of the spec.

```
# required for the helper method
require 'uri'
require 'net/http'

# helper method
def send_json_request(uri, request_type, params = {})
  url = URI(uri)
  req = nil
  if request_type == "GET"
    req = Net::HTTP::Get.new(url, 'Content-Type' => 'application/json')
  elsif request_type == "POST"
    req = Net::HTTP::Post.new(url, 'Content-Type' => 'application/json')
  end
  req.body = params.to_json
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = (url.scheme == "https")
  http.request(req)
end

# TEST CASE 1 (from the spec)
# =========================
# Create Credit Card
    params_for_credit_card = {
      format: :json,
      name: DateTime.now.strftime("%Q"), # to ensure no duplicates
      current_payment_period_start_date: "01/12/2017" # day/month/year
    }
    create_credit_card = JSON.parse(send_json_request("https://isaac-hernandez-fair-exercise.herokuapp.com/credit_cards" ,"POST", params_for_credit_card).body)
    credit_card_id = create_credit_card["response"]["credit_card"]["id"]
# Get Credit Card Info
    get_credit_card = JSON.parse(send_json_request("https://isaac-hernandez-fair-exercise.herokuapp.com/credit_cards/#{credit_card_id}", "GET", { format: :json }).body)
# Create Transaction ($500 initial balance)
    params_for_transaction = {
      format: :json,
      date: "30/11/2017",
      transaction_type: "DRAW",
      amount: 500,
      credit_card_id: credit_card_id
    }
    create_transaction = JSON.parse(send_json_request("https://isaac-hernandez-fair-exercise.herokuapp.com/credit_cards/#{credit_card_id}/transactions", "POST", params_for_transaction).body)
# Close Payment Period
    close_payment_period = JSON.parse(send_json_request("https://isaac-hernandez-fair-exercise.herokuapp.com/credit_cards/#{credit_card_id}/close_payment_period", "GET", { format: :json }).body)
    "The interest for this payment period is $#{close_payment_period["response"]["transaction"]["amount"]} and the total balance due is $#{close_payment_period["response"]["credit_card"]["current_balance"]}."


# TEST CASE 2 (from the spec)
# =========================
# Create Credit Card
    params_create_credit_card = {
      format: :json,
      name: DateTime.now.strftime("%Q"), # to ensure no duplicates
      current_payment_period_start_date: "01/12/2017"
    }
    create_credit_card = JSON.parse(send_json_request("https://isaac-hernandez-fair-exercise.herokuapp.com/credit_cards" ,"POST", params_create_credit_card).body)
    credit_card_id = create_credit_card["response"]["credit_card"]["id"]
# Get Credit Card Info
    get_credit_card = JSON.parse(send_json_request("https://isaac-hernandez-fair-exercise.herokuapp.com/credit_cards/#{credit_card_id}", "GET", { format: :json }).body)
# Create Transaction ($500 initial balance)
    params_for_transaction = {
      format: :json,
      date: "30/11/2017",
      transaction_type: "DRAW",
      amount: 500,
      credit_card_id: credit_card_id
    }
    create_transaction = JSON.parse(send_json_request("https://isaac-hernandez-fair-exercise.herokuapp.com/credit_cards/#{credit_card_id}/transactions", "POST", params_for_transaction).body)
# Create Transaction ($200 pay on day 15)
    params_for_transaction = {
      format: :json,
      date: "15/12/2017",
      transaction_type: "PAYMENT",
      amount: 200,
      credit_card_id: credit_card_id
    }
    create_transaction = JSON.parse(send_json_request("https://isaac-hernandez-fair-exercise.herokuapp.com/credit_cards/#{credit_card_id}/transactions", "POST", params_for_transaction).body)
# Create Transaction ($100 draw on day 25)
    params_for_transaction = {
      format: :json,
      date: "25/12/2017",
      transaction_type: "DRAW",
      amount: 100,
      credit_card_id: credit_card_id
    }
    create_transaction = JSON.parse(send_json_request("https://isaac-hernandez-fair-exercise.herokuapp.com/credit_cards/#{credit_card_id}/transactions", "POST", params_for_transaction).body)
# Close Payment Period
    close_payment_period = JSON.parse(send_json_request("https://isaac-hernandez-fair-exercise.herokuapp.com/credit_cards/#{credit_card_id}/close_payment_period", "GET", { format: :json }).body)
    "The interest for this payment period is $#{close_payment_period["response"]["transaction"]["amount"]} and the total balance due is $#{close_payment_period["response"]["credit_card"]["current_balance"]}."
```
