document.addEventListener('DOMContentLoaded', async () => {

    //First fetch the publishable key

    const {publishableKey} = await fetch('/config').then (r => r.json())
    const stripe = Stripe(publishableKey)

    //Second, create the payment intent on the server

    const {clientSecret} = await fetch("/create-payment-intent", {
        method: "POST",
        headers: {
            'Content-Type': 'application/json'
        }
    }).then(r => r.json()) 

    //Third, render the payment elements on the html page

    const elements = stripe.elements({ clientSecret })
    const paymentElement = elements.create('payment')
    paymentElement.mount('#payment-element')

    const form = document.getElementById('payment-form')
    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const {error} = await stripe.confirmPayment({
            elements,
            confirmParams: {
                return_url: window.location.href.split('?') + 'complete'
            }
        })
        if (error) {
            const messages = document.getElementById('error-messages')
            messages.innerText = error.message
        }
    })
})