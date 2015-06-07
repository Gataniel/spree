class Spree::Calculator::Shipping::EmsCalculator < Spree::Calculator
  def self.description
    'Калькулятор экспресс доставки EMS'
  end

  def compute_package(package)
    # Returns the value after performing the required calculation
  end
end
