# frozen_string_literal: true

require 'stripe'
require 'sinatra'
require 'dotenv'

# Replace if using a different env file or config
Dotenv.load

# For sample support and debugging, not required for production:
Stripe.set_app_info(
  'stripe-samples/<name-of-sample>/[<name-of-integration-type>]',
  version: '0.0.1',
  url: 'https://github.com/stripe-samples'
)
Stripe.api_version = '2020-08-27'
Stripe.api_key = ENV['STRIPE_SECRET_KEY']

set :static, true
set :public_folder, File.join(File.dirname(__FILE__), ENV['STATIC_DIR'])
set :port, 4250

get '/' do
  content_type 'text/html'
  send_file File.join(settings.public_folder, 'index.html')
end

get '/config' do
  content_type 'application/json'
  {
    publishableKey: ENV['STRIPE_PUBLISHABLE_KEY'],
  }.to_json
end

post '/create-payment-intent' do
payment_intent = Stripe::PaymentIntent.create({
  amount: 1099,
  currency: 'usd',
  automatic_payment_methods: { enabled: true }
})
{ clientSecret: payment_intent.client_secret }.to_json
end

get '/complete' do
 payment_intent = Stripe::PaymentIntent.retrieve(params[:payment_intent])
 payment_intent.to_json
end


post '/webhook' do
  # You can use webhooks to receive information about asynchronous payment events.
  # For more about our webhook events check out https://stripe.com/docs/webhooks.
  webhook_secret = ENV['STRIPE_WEBHOOK_SECRET']
  payload = request.body.read
  if !webhook_secret.empty?
        # Retrieve the event by verifying the signature using the raw body and secret if webhook signing is configured.
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, webhook_secret
      )
    rescue JSON::ParserError => e
      # Invalid payload
      status 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      puts '⚠️  Webhook signature verification failed.'
      status 400
      return
    end
  else
    data = JSON.parse(payload, symbolize_names: true)
    event = Stripe::Event.construct_from(data)
  end

  case event.type
  when 'payment_intent.succeeded'
    puts '🔔  Payment received!'
  end

  content_type 'application/json'
  {
    status: 'success'
  }.to_json
end
