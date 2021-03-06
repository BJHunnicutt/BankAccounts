# Bank Account

require 'faker'
require 'chronic'
require 'csv'
require 'awesome_print'
require 'rainbow'


module Bank
  # Class for account balance information
  class Account
    @@accounts =[]
    # Allow balance, id, and owner to be read
    attr_reader :balance, :id, :owner, :minimum_balance, :withdrawal_fee
    # Initialize the account information and concatinate an array with all initialized accounts
    def initialize(account_no, balance, date, owner = nil)
      @balance = balance
      @minimum_balance = 0
      @withdrawal_fee = 0
      minimum_balance_check(minimum_balance, balance)
      @id = account_no
      @date_created = Chronic.parse(date)
      # Make sure there are no duplicate ID #s?
      if owner == nil
        # Put in a fake owner it one is not input
        @owner = Bank::Owner.new(owner_id: '', first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, street_address: Faker::Address.street_address, city: Faker::Address.city, state: Faker::Address.state)
      else
        @owner = owner
      end

      # Storing all the accounts in a class variable
      @@accounts << self
    end

    def minimum_balance_check(minimum_balance, balance)
      if balance < minimum_balance
        raise ArgumentError.new("You cannot open an account with less than $#{minimum_balance}.")
      end
    end

    # Class method to initialize new accounts with thier info and owners
    def self.import_csvs
      # ### BASIC REQUIREMENTS VERSION:
      # # Read the accounts.csv file and create new Account objects for each account in the file
      # CSV.open("./support/accounts.csv", 'r').each do |line|
      #   # I did have this as:
      #   # @@accounts << self.new(line[0].to_i, line[1].to_f/100, line[2])
      #   # ... but since I am shoveling self in the initialize, it doesn't have to happen here.
      #   self.new(line[0].to_i, line[1].to_f/100, line[2])
      # end

      #### OPTIONAL ENHANCEMENTS VERSION:
      owners = []
      # Read the owners.csv file and create an array of Owner objects
      CSV.open("./support/owners.csv", 'r').each do |line|
        owners << Bank::Owner.new(owner_id: line[0].to_i, first_name: line[2], last_name: line[1], street_address: line[3], city: line[4], state: line[5])
      end
      ### Initialize new accounts with their corresponding owners

      # First, go line-by-line through the accounts
      CSV.open("./support/accounts.csv", 'r').each do |line|
        # Second find the correspondence between the account id's and the owner_id's
        CSV.open("./support/account_owners.csv", 'r').each do |corespondence|
          # if you're at a line of the correspondence file, that == account id
          if corespondence[0].to_i == line[0].to_i
            # go through the owner array and find the owner corresponding to that id
            owners.each do |owner|
              if owner.owner_id == corespondence[1].to_i
                # Finally, initialize that new account with the account and owner info
                self.new(line[0].to_i, line[1].to_f/100, line[2], owner)
              end
            end
          end
        end
      end

    end

    # Class method to retreive a collection of all Owner instances
    def self.all
      return @@accounts
    end

    # Class method to get the Account object for a specific account number
    def self.find(id)
      @@accounts.each do |account|
        if account.id == id
          return account
        end
      end
    end

    # Method for withdrawing from the Account
    def withdraw(withdrawal_amt = 0)
      if (@balance - withdrawal_amt - withdrawal_fee) < @minimum_balance
        puts Rainbow("\n*** SORRY! you cannot withdraw your account below $#{minimum_balance}. This transaction will incur a fee of $#{withdrawal_fee}, making your requested withdrawal amount $#{withdrawal_amt + withdrawal_fee}, but your current balance is $" + sprintf("%.2f", @balance) + ". ***\n\n").red
        return @balance
      else
        @balance = @balance - withdrawal_amt - withdrawal_fee
      end
    end

    # Method for depositing in the Account
    def deposit(deposit_amt = 0)
      # Give an argument error if they try to deposit a negative amount
      if deposit_amt < 0
        raise ArgumentError.new("You cannot deposit a negative amount.")
      end
      @balance = @balance + deposit_amt
      return @balance
    end

    # Instance method to return a description of an initialized account
    def account_overview
      return "*** Account \##{@id} has belonged to #{@owner.first_name} #{@owner.last_name} since #{@date_created} and has a balance of $" + sprintf("%.2f", @balance) + ". ***"
    end
  end

### Owner Class to store information about those who own the Accounts
  class Owner
    attr_accessor :owner_id, :first_name, :last_name, :street_address, :city, :state

    def initialize(info_hash)
      @owner_id  = info_hash[:owner_id]
      @first_name  = info_hash[:first_name]
      @last_name   = info_hash[:last_name]
      @street_address  = info_hash[:street_address]
      @city        = info_hash[:city]
      @state       = info_hash[:state]
    end
  end

### SavingsAccount class which should inherit behavior from the Account class
  class SavingsAccount < Account

    # The minimum balance for the savings account is different, so need to overwrite these
    def initialize(account_no, balance, date, owner = nil)
      super
      @minimum_balance = 10
      # Each withdrawal 'transaction' incurs a fee of $2
      @withdrawal_fee = 2
      # Have to call this again or else it just uses the minimum_balance from Account class
      minimum_balance_check(minimum_balance, balance)
    end

    # Instance Method for withdrawing from the Account
    def withdraw(withdrawal_amt = 0)
      super
    end

    ## Instance method to Add interest to the SavingsAccount:
    def add_interest(rate) # rate input in percent (i.e. 0.25%)
      interest = balance * rate/100
      @balance = @balance + interest
      ###### Should i calculate interese since the account was opened... ??? ##
      return interest
    end

  end

### CheckingAccount class which should inherit behavior from the Account class
  class CheckingAccount < Account

    # The initial balance cannot be less than $10. will raise an ArgumentError
    def initialize(account_no, balance, date, owner = nil)
      super
      @@check_no = 1
      # Each direct withdrawal 'transaction' from the checking account incurs a fee of $1
      @withdrawal_fee = 1
    end


    def withdraw_using_check(withdrawal_amt)

      # Allow the account to go into overdraft up to -$10 but not any lower
      check_minimum_balance = -10
      additional_check_fee = 0

      # 3 free check uses allowed in one month, but any subsequent use adds a $2 transaction fee
      if @@check_no > 3
        additional_check_fee = 2
      end

      # Determine if withdrawal amount below minimum, if not, withdraw
      if (@balance - withdrawal_amt - additional_check_fee) < check_minimum_balance
        puts Rainbow("\n*** SORRY! you cannot use a check that withdraws your checking account below $#{check_minimum_balance}. This transaction will incur a fee of $#{additional_check_fee}, making your requested withdrawal amount $#{withdrawal_amt + additional_check_fee}, but your current balance is $" + sprintf("%.2f", @balance) + ". ***\n\n").red
        return @balance
      else
        @balance = @balance - withdrawal_amt - additional_check_fee
      end
      # Keep a tally of checks used
      puts "Check ##{@@check_no}, balance: #{@balance}, withdrawal amt: #{withdrawal_amt}, fee: #{additional_check_fee}"
      @@check_no += 1
    end

    # Resets the number of checks used to zero
    def reset_checks
      @@check_no = 1
    end
  end

end




###### ----------------- Checking Wave 1 -------------------- #########
b1 = Bank::Account.new(1000,100000,'1000-01-11 11:00:00 -0800')
b2 = Bank::Account.new(22222,2222222,'1222-02-22 22:00:00 -0800')

b1.deposit(100.50)
b1.withdraw(500)


###### ----------------- Checking Wave 2 -------------------- #########
bulk_accounts = Bank::Account.import_csvs

puts
puts Rainbow(b1.account_overview).yellow
puts "\n"
puts "Balance: #{b1.balance}"
puts "Account ID: #{b1.id}"
puts "Owner: #{b1.owner.first_name} #{b1.owner.last_name}"

puts
puts "There are #{Bank::Account.all.length} accounts"
puts Rainbow(Bank::Account.find(1214).account_overview).yellow


###### ----------------- Checking Wave 3 -------------------- #########
s1 = Bank::SavingsAccount.new(1,5,'1111-01-11 11:00:00 -0800')
s1.withdraw(20)
puts "Current balance: #{s1.balance}"
puts "Interest: #{s1.add_interest(0.25)}"
puts

c1 = Bank::CheckingAccount.new(2,50,'2222-02-22 22:00:00 -0200')
puts Rainbow(Bank::CheckingAccount.find(2).account_overview).yellow
c1.withdraw(4)
puts
5.times {c1.withdraw_using_check(5)}
#
# c1.deposit(27)
# puts "Current balance: #{c1.balance}"
# 5.times {c1.withdraw_using_check(5)}
#
# c1.reset_checks
# c1.deposit(500)
# puts "Current balance: #{c1.balance}"
# 5.times {c1.withdraw_using_check(5)}
