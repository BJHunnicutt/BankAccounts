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
      ### This cannot be the best way to do this....
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

  class MoneyMarketAccount < SavingsAccount # By inheriting SavingsAccount don't have to rewrite interest method
    attr_reader :active, :below_minimum_balance_fee

    def initialize(account_no, balance, date, owner = nil)
      super
      @minimum_balance = 10000
      @@transaction_no = 1
      # Allows the account to become inactive if it drops below minimum_balance
      @active = true
      # Each direct withdrawal 'transaction' from the checking account incurs a fee of $1
      @withdrawal_fee = 0
      @below_minimum_balance_fee = 100

      minimum_balance_check(minimum_balance, balance)
    end

    def withdraw(withdrawal_amt)

      if check_transaction_status # If there are < 6 transactions this month
        if check_account_status # If the account isn't already below minimum
          # Determine if withdrawal amount below minimum, if not, withdraw
          if (@balance - withdrawal_amt) < minimum_balance
            overdraft_warning(withdrawal_amt, below_minimum_balance_fee)
            @balance = @balance - withdrawal_amt - below_minimum_balance_fee
          else
            @balance = @balance - withdrawal_amt
          end
          add_transaction
        end
      end
      # puts "Transaction ##{@@transaction_no-1}, balance: #{@balance}, withdrawal amt: #{withdrawal_amt}"
      return @balance
    end

    # Method for depositing in the Account
    def deposit(deposit_amt = 0)
      # Exception to transaction limit: A deposit performed to reach or exceed the minimum balance of $10,000 is not counted as part of the 6 transactions.
      if check_account_status == false && (@balance + deposit_amt >= minimum_balance)
        puts Rainbow("Thank you for your deposit, your account has been unfrozen.").green
        super # but don't add to transactions
      elsif check_transaction_status
        super

        # Each deposit will be counted against the maximum number of transactions
        add_transaction
        if check_account_status
          @active = true
        end

      end

      return @balance
    end


    def add_transaction
      @@transaction_no += 1 # Keep a tally of transactions used
      if @@transaction_no > 6
        @active = false
      end
    end

    def check_transaction_status
      if @@transaction_no > 6
        puts Rainbow("\nYou have reached your transaction limit for the month, please use >> Bank::MoneyMarketAccount.reset_transactions to continue to the next month.").orange
        return false
      else
        return true
      end
    end

    def check_account_status
      if @balance < minimum_balance
        puts Rainbow("\n*** Your Money Market Account is FROZEN because it is below it's minimum balance of $#{minimum_balance}. Please deposit at least #{minimum_balance - @balance} to make any further withdrawals. ***").red
        return false
      else
        return true
      end
    end

    def overdraft_warning(withdrawal_amt, below_minimum_balance_fee = 0)
      puts Rainbow("\n*** This transaction brings your Money Market Account below it's minimum balance of $#{minimum_balance} and will incur a fee of $#{below_minimum_balance_fee}, making your new balance $" + sprintf("%.2f", (@balance - withdrawal_amt - below_minimum_balance_fee)) + ". Please deposit at least $#{minimum_balance - (@balance - withdrawal_amt - below_minimum_balance_fee)} to make any further withdrawals. ***").yellow
      @active = false
    end

    # Resets the number of checks used to zero
    def reset_transactions
      @@transaction_no = 1
      puts "Welcome to the new month!"
      @active = true
    end

    def self.transaction_no_reader
      return @@transaction_no
    end

  end
end




###### ----------------- Checking Wave 1 -------------------- #########
# b1 = Bank::Account.new(1000,100000,'1000-01-11 11:00:00 -0800')
# b2 = Bank::Account.new(22222,2222222,'1222-02-22 22:00:00 -0800')
#
# b1.deposit(100.50)
# b1.withdraw(500)
#
#
# ###### ----------------- Checking Wave 2 -------------------- #########
# bulk_accounts = Bank::Account.import_csvs
#
# puts
# puts Rainbow(b1.account_overview).yellow
# puts "\n"
# puts "Balance: #{b1.balance}"
# puts "Account ID: #{b1.id}"
# puts "Owner: #{b1.owner.first_name} #{b1.owner.last_name}"
#
# puts
# puts "There are #{Bank::Account.all.length} accounts"
# puts Rainbow(Bank::Account.find(1214).account_overview).yellow
#
#
# ###### ----------------- Checking Wave 3 -------------------- #########
# s1 = Bank::SavingsAccount.new(1,30,'1111-01-11 11:00:00 -0800')
# s1.withdraw(10)
# puts "Current balance: #{s1.balance}"
# puts "Interest: #{s1.add_interest(0.25)}"
# puts
#
# c1 = Bank::CheckingAccount.new(2,50,'2222-02-22 22:00:00 -0200')
# puts Rainbow(Bank::CheckingAccount.find(2).account_overview).blue
# c1.withdraw(4)
# puts
# 5.times {c1.withdraw_using_check(5)}


###### ------------- Checking Wave 3 OPTIONAL -------------- #########

m1 = Bank::MoneyMarketAccount.new(255555,13000,'1999-12-31 23:59:59 -0200')
puts Rainbow(Bank::CheckingAccount.find(255555).account_overview).cyan
puts

3.times {puts "\nNew WITHDRAWAL:"; puts m1.withdraw(5000)}
puts

puts "\nNew DEPOSIT:"
puts m1.deposit(500000)
puts

5.times {puts "\nNew WITHDRAWAL:"; puts m1.withdraw(5000)}
puts

puts "\nNew DEPOSIT:"
puts m1.deposit(500000)
puts

puts "\nNew MONTH:"
puts m1.reset_transactions
puts

puts "\nNew DEPOSIT:"
puts m1.deposit(500000)
puts

puts "Interest: #{m1.add_interest(0.25)}"
