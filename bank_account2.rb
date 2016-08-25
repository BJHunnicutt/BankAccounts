# Bank Account

require 'faker'
require 'chronic'
require 'csv'
require 'awesome_print'


module Bank
  # Class for account balance information
  class Account
    @@accounts =[]
    # Allow balance, id, and owner to be read
    attr_reader :balance, :id, :owner
    # Initialize the account information and concatinate an array with all initialized accounts
    def initialize(account_no, balance, date, owner = nil)
      if balance < 0
        raise ArgumentError.new("You cannot open an account with a negative amount.")
      end
      @balance = balance
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

    # Class method to initialize new accounts with thier info and owners
    def self.all

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
      # Initialize new accounts with their corresponding owners
      # First, go line-by-line through the accounts
      CSV.open("./support/accounts.csv", 'r').each do |line|
        # Second find the correspondence between the account id's and the owner_id's
        CSV.open("./support/account_owners.csv", 'r').each do |corespondence|
          # if you're at a line of the correspondence file, that == account id
          if corespondence[0].to_i == line[0].to_i
            # go through the owner array and find the owner corresponding to that id
            owners.each do |owner|
              if owner.owner_id == corespondence[1].to_i
                # Finally, initialize that new account with the owner info
                self.new(line[0].to_i, line[1].to_f/100, line[2], owner)
              end
            end
          end
        end
      end

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

    # Instance method to return a description of an initialized account
    def account_overview
      return "***Account \##{@id} has belonged to #{@owner.first_name} #{@owner.last_name} since #{@date_created} and has a balance of $" + sprintf("%.2f", @balance)
    end
  end
  # Class to store information about those who own the Accounts
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
end

b1 = Bank::Account.new(1000,100000,'1000-01-11 11:00:00 -0800')
b2 = Bank::Account.new(22222,2222222,'1222-02-22 22:00:00 -0800')

b1.deposit(100.50)
b1.withdraw(50)

puts b1.account_overview
puts "\n\n"
puts "Balance: #{b1.balance}"
puts "Account ID: #{b1.id}"
puts "Owner: #{b1.owner.first_name} #{b1.owner.last_name}"

puts
puts "There are #{Bank::Account.all.length} accounts"
ap Bank::Account.find(1214).account_overview
