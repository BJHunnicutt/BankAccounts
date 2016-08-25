# Bank Account

require 'faker'

module Bank
  # Class for account balance information
  class Account
    # Allow balance to be read
    attr_reader :balance, :id, :owner
    # Initialize balance and generate an ID
    def initialize(balance = 0)
      if balance < 0
        raise ArgumentError.new("You cannot open an account with a negative amount.")
      end
      @balance = balance
      @id = Faker::Company.swedish_organisation_number
      # Make sure there are no duplicate ID #s?
      @owner = Bank::Owner.new(account_id: @id, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, street_address: Faker::Address.street_address, city: Faker::Address.city, state: Faker::Address.state, zip: Faker::Address.zip)
    end
    # Method for withdrawing from the Account
    def withdraw(withdrawal_amt = 0)
      if @balance - withdrawal_amt < 0
        puts "Sorry, withdraw more the account balance."
        return @balance
      else
        @balance = @balance - withdrawal_amt
        return @balance
      end
    end
    # Method for depositing in the Account
    def deposit(deposit_amt = 0)
        @balance = @balance + deposit_amt
      return @balance
    end

    def account_overview
      return "***Account \##{@owner.account_id} belongs to #{@owner.first_name} #{@owner.last_name} and has a balance of $#{@balance}***"
    end
  end
  # Class to store information about those who own the Accounts
  class Owner
    attr_accessor :account_id, :first_name, :last_name, :street_address, :city, :state, :zip

    def initialize(info_hash)
      @account_id  = info_hash[:account_id]
      @first_name  = info_hash[:first_name]
      @last_name   = info_hash[:last_name]
      @street_address  = info_hash[:street_address]
      @city        = info_hash[:city]
      @state       = info_hash[:state]
      @postal_code = info_hash[:zip]
    end
  end
end

b1 = Bank::Account.new(100)

b1.deposit(100.50)
b1.withdraw(50)

puts
puts b1.account_overview
puts "\n\n"
puts b1.balance
puts b1.id
puts b1.owner.last_name
