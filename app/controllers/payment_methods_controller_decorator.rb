#encoding: utf-8
Spree::Admin::PaymentMethodsController.class_eval do
	before_filter :check_onpay_edit	
	
	def edit
		render :template => 'templates/payment_methods/edit.html.erb' if @@onpay_way		
	end

	private

	def check_onpay_edit
		@payment_method.class == Gateway::Onpay ?	@@onpay_way = true : @@onpay_way = false
	end

end
