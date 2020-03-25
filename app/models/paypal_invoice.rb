class PaypalInvoice < ApplicationRecord
  belongs_to :user
  belongs_to :page_unlock_promo_code, optional: true

  after_create :double_check_webhooks_for_24_hours

  def double_check_webhooks_for_24_hours
    # We queue up a job to manually check this invoice's status after 5 minutes
    # just in case Paypal never sends us a webhook, or the user never get redirected
    PayPalPrepayProcessingJob
      .set(wait: 5.minutes)
      .perform_later(self.paypal_id)
  end

  def capture_funds!
    SlackService.post('#subscriptions',
      "Capturing $#{self.amount_cents / 100.0} from a prepaid Paypal subscription"
    )

    PaypalService.capture_invoice_funds(self.paypal_id)
    PayPalPrepayProcessingJob.perform_now(self.paypal_id)
  end

  def generate_promo_code!
    self.page_unlock_promo_code = PageUnlockPromoCode.create(
      code: 'PP-' + (0...8).map { (65 + rand(26)).chr }.join + '-' + (0...8).map { (65 + rand(26)).chr }.join,
      page_types: Rails.application.config.content_types[:premium].map(&:name),
      uses_remaining: 1,
      days_active: 30 * self.months.to_i,
      internal_description: "Prepaid with PayPal",
      description: "Prepaid Premium subscription"
    )
    self.save!

    if PromoService.active?(:promo_bogo) && (self.months == 3 || self.months == 6)
      # During this promo, we create a separate Invoice + PromoCode also
      self.user.paypal_invoices.create(
        paypal_id: "None -- Created from promo_bogo promo",
        status:       self.status,
        user_id:      self.user_id,
        months:       self.months,
        amount_cents: 0,
        page_unlock_promo_code: PageUnlockPromoCode.create(
          code:                 'BOGO-' + (0...8).map { (65 + rand(26)).chr }.join + '-' + (0...8).map { (65 + rand(26)).chr }.join,
          page_types:           Rails.application.config.content_types[:premium].map(&:name),
          uses_remaining:       1,
          days_active:          30 * self.months.to_i,
          internal_description: "promo_bogo duplicate code",
          description:          "Your free buy-one-get-one-free Premium Code",
        ),
        approval_url: nil,
        payer_id:     self.payer_id
      )
    end
  end

  def activateable?
    self.status == 'COMPLETED' &&
      page_unlock_promo_code.present? &&
      page_unlock_promo_code.uses_remaining > 0
  end
end
