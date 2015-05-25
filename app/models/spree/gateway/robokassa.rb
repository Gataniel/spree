module Spree
  class Gateway::Robokassa < Gateway
    preference :password1, :password
    preference :password2, :password
    preference :mrch_login, :string

    def provider_class
      self.class
    end

    def method_type
      "robokassa"
    end

    def test?
      options[:test_mode] == true
    end

    def url
      self.test? ? "http://test.robokassa.ru/Index.aspx" : "https://merchant.roboxchange.com/Index.aspx"
    end

    def self.current
      self.where(:type => self.to_s, :environment => Rails.env, :active => true).first
    end

    # def supports?(source)
    #   false
    # end

    # def source_required?
    #   false
    # end

    # def auto_capture?
    #   false
    # end

    # def confirmation_required?
    #   true
    # end

    # # Indicates whether its possible to void the payment.
    # def can_void?(payment)
    #   !payment.void?
    # end

    # # Indicates whether its possible to capture the payment
    # def can_capture?(payment)
    #   payment.pending? || payment.checkout?
    # end

    def desc
      "<p>
        <label> #{I18n.t('robokassa.success_url')}: </label> http://[domain]/gateway/robokassa/success<br />
        <label> #{I18n.t('robokassa.result_url')}: </label> http://[domain]/gateway/robokassa/result<br />
        <label> #{I18n.t('robokassa.fail_url')}: </label> http://[domain]/gateway/robokassa/fail<br />
      </p>"
    end
  end
end