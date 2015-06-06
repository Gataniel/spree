xml.instruct! :xml, :version =>"1.0"
xml.result{
	xml.code(@out["code"])
	xml.pay_for(@out["pay_for"])
	xml.comment(@out["comment"])
	xml.md5(@out["md5"])
}	
