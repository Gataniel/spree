#encoding: utf-8
class Spree::Gateway::Onpay < Spree::Gateway
 	preference :priv_code, :string
  preference :onpay_login, :string
	preference :price_final, :boolean, :default => true
  preference :convert_currency, :boolean, :default => true
	preference :pay_type, :string, :default => 'fix'
	preference :currency, :string,:default => 'RUR'

  def provider_class
    self.class
  end

  def method_type
    "onpay"
  end

  def url
    "https://secure.onpay.ru/pay/#{self.options[:onpay_login]}" 
  end

  def self.current
    self.where(:type => self.to_s, :environment => Rails.env, :active => true).first
  end

end
