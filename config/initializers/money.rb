# TOFIX default rubl sign ios not recognised by browsers

rub_curr = {
  :priority        => 10000,
  :iso_code        => "RUB",
  :iso_numeric     => "643",
  :name            => "Российский Рубль",
  :symbol          => "руб.",
  :html_entity     => "руб.",
  # :subunit         => "коп.",
  :subunit_to_unit => 100,
  :separator       => ".",
  :delimiter       => ","
}

Money::Currency.register(rub_curr)