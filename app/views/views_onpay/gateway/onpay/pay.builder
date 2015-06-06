xml.instruct! :xml, :version =>"1.0"
xml.result{
	xml.code(@out["code"])
	xml.comment(@out["comment"])
	xml.onpay_id(@out["onpay_id"])
	xml.pay_for(@out["pay_for"])
	xml.order_id(@out["pay_for"])
	xml.md5(@out["md5"])
}	
