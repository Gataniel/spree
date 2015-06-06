#encoding: utf-8
class Spree::Gateway::OnpayController < Spree::BaseController
  include Spree::Core::ControllerHelpers::Order

  helper 'spree/products', 'spree/orders'

  skip_before_filter :verify_authenticity_token, :only => [:api]
  before_filter :load_order,                     :only => [:api]
  ssl_required :show
  # render layout: false
  
  def show
    @order =  Spree::Order.find(params[:order_id])
    @gateway = @order.available_payment_methods.find{|x| x.id == params[:gateway_id].to_i }

    if @order.blank? || @gateway.blank?
      flash[:error] = I18n.t("invalid_arguments")
      redirect_to :back
    else
			@pay_type = @gateway.options[:pay_type]
			@price = sprintf("%.2f",@order.total.to_f).to_f
			@currency = @gateway.options[:currency]
			@convert_currency = @gateway.options[:convert_currency] ? 'yes':'no'
			@price_final = @gateway.options[:price_final] ? 'yes':'no'
			@user_email = @order.email
			@md5 = Digest::MD5.hexdigest([@gateway.options[:pay_type],
																	sprintf("%.1f",@order.total.to_f).to_f,
																	@currency,
																	@order.id,
																	@convert_currency,
																	@gateway.options[:priv_code]].join(';'))

      render :action => :show
    end
  end

	def api
		# @out - hash for answer view
		@out = Hash.new
		@out["pay_for"] = params["pay_for"]

		if params["type"] == "check" then
			if params["md5"] == Digest::MD5.hexdigest([params["type"],
																												params["pay_for"],
																												params["order_amount"],
																												params["order_currency"],
																												@gateway.options[:priv_code]].join(';')).upcase
				if @gateway.options[:test_mode] then
					tst_valid_check(params["pay_for"],params["order_amount"],params["order_currency"]) ? out_code_comment(0,"All,OK") :	out_code_comment(3,"Error on parameters check")
				else
					valid_check(params["pay_for"],params["order_amount"],params["order_currency"]) ? out_code_comment(0,"All,OK") :	out_code_comment(3,"Error on parameters check")					
				end 
				@out["md5"] = create_check_md5(params["type"],params["pay_for"],params["order_amount"],
																		 params["order_currency"],@out["code"],@gateway.options[:priv_code])
				render :action => "check"
			else
				out_code_comment(7,"MD5 signature wrong")
				@out["md5"] = create_check_md5(params["type"],params["pay_for"],params["order_amount"],
																		 params["order_currency"],@out["code"],@gateway.options[:priv_code])
				render :action => "check"
			end
		end


		if params["type"] == "pay" then 
			if params["md5"] == Digest::MD5.hexdigest([params["type"],
																											params["pay_for"],
																											params["onpay_id"],
																											params["order_amount"],
																											params["order_currency"],
																											@gateway.options[:priv_code]].join(';')).upcase
				@out["onpay_id"] = params["onpay_id"]
				if @gateway.options[:test_mode] then
					if tst_valid_check(params["pay_for"],params["order_amount"],params["order_currency"]) then


            create_payment(params["order_amount"].to_f)
						out_code_comment(0,"OK")	
					else
						out_code_comment(3,"Error on parameters check")
					end
				else
					if valid_check(params["pay_for"],params["order_amount"],params["order_currency"]) then

            create_payment(params["order_amount"].to_f)
						out_code_comment(0,"OK")	
					else
						out_code_comment(3,"Error on parameters check")
					end
				end
				
				
				@out["md5"] = create_pay_md5(params["type"],params["pay_for"],params["onpay_id"],params["pay_for"],params["order_amount"],
																		params["order_currency"],@out["code"],@gateway.options[:priv_code])																	 
				render :action => "pay"
			else
				out_code_comment(7,"MD5 signature wrong")			
				@out["onpay_id"] = params["onpay_id"]
				@out["md5"] = create_pay_md5(params["type"],params["pay_for"],params["onpay_id"],params["pay_for"],params["order_amount"],
																	 params["order_currency"],@out["code"],@gateway.options[:priv_code])				 
				render :action => "pay"
			end
		end

	end



  private

	def create_payment(order_amount)
 	     		# payment = @order.payments.build(:payment_method => Spree::PaymentMethod.find_by_type('Gateway::Onpay'))
          payment_method = Spree::PaymentMethod.find(7)
          ololo = {}
          ololo[:email] = @order.email
          ololo[:currency] = @order.currency
          ololo[:payment_method_id] = payment_method.id
          ololo[:order_id] = @order.id
          skrill_transaction = Spree::SkrillTransaction.create_from_postback ololo

          payment = @order.payments.where(:state => "pending",
                                          :payment_method_id => payment_method).first



          if payment
            payment.source = skrill_transaction
            payment.save
          else
            payment = @order.payments.create(:amount => order_amount,
                                             :source => skrill_transaction,
                                             :payment_method => payment_method)
          end

          payment.started_processing!

          payment.complete!


          spsr = true
          @order.line_items.each do |line_item|
            line_item.product.master.stock_items.each do |stock_item|
              if display_count(stock_item) < line_item.quantity
                spsr = false
                break
              end
            end
          end

          if spsr
          @order.shipments.each do |s|
            s.state = 'ready'
            s.save
          end
          @order.shipment_state = 'ready'
          end

          @order.payment_state = 'paid'
          @order.completed_at = Time.now
          @order.state = 'complete'
          # @order.finalize!
          @order.save!
          Spree::OrderMailer.confirm_email(@order.id).deliver

    # Rails.logger.info "payment.completed? -------> #{payment.completed?}"
          #
          # unless payment.completed?
          #   case params[:status]
          #     when "0"
          #       payment.pend #may already be pending
          #     when "2" #processed / captured
          #       payment.complete!
          #     when "-1", "-2"
          #       payment.failure!
          #     else
          #       raise "Unexpected payment status"
          #   end
          # end

          # payment = @order.payments.build(:payment_method => @order.payment_method)
          # payment.payment_method = Spree::PaymentMethod.find_by_type('Gateway::Onpay')
          # payment.state = "completed"
          # payment.amount = order_amount
          # payment.save
 	     		# @order.save!
 	     		# @order.next! until @order.state == "complete"
 	     		# @order.update!
  end



  def object_params
    if params[:payment] and params[:payment_source] and source_params = params.delete(:payment_source)[params[:payment][:payment_method_id]]
      params[:payment][:source_attributes] = source_params
    end

    params.require(:payment).permit(permitted_payment_attributes)
  end



	def create_check_md5(type,pay_for,order_amount,order_currency,code,priv_code)
		md5 = Digest::MD5.hexdigest([type,pay_for,order_amount,order_currency,code,priv_code].join(';')).upcase
		return md5
	end

	def create_pay_md5(type,pay_for,onpay_id,order_id,order_amount,order_currency,code,priv_code)
		md5 = Digest::MD5.hexdigest([type,pay_for,onpay_id,order_id,order_amount,order_currency,code,priv_code].join(';')).upcase
		return md5
	end

	def valid_check(pay_for,order_amount,order_currency)
		return false if @order.state == "complete"
		return false until order_amount.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
		return false until pay_for == @order.id.to_s
		return false until order_amount.to_f == sprintf("%.1f",@order.total).to_f
		return false if order_currency != @gateway.options[:currency]
		return true
	end
	
	def tst_valid_check(pay_for,order_amount,order_currency)
		return false if @order.state == "complete"
		return false until order_amount.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
		return false until pay_for == @order.id.to_s
		return false until order_amount.to_f == sprintf("%.1f",@order.total).to_f
		return true
	end

	def out_code_comment(code,comment)
		@out["code"] = code
		@out["comment"] = comment
	end

  def load_order
    @order = Spree::Order.find_by_id(params["pay_for"])
    @gateway = Spree::Gateway::Onpay.current
  end

end
