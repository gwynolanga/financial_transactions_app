# Technical Assessment for [UniFin Cryptobank](https://unifincryptobank.com/)

### Context

Develop a basic functionality for processing financial transactions between system users. Transactions can be executed
in different currencies and can be scheduled for future execution.

Expected duration: 5 hours. Submission format: Github repository link

### Core Requirements

#### Functional Requirements
1. Frontend:
    * Creating transactions (money transfer between users)
    * Checking transaction status
    * Retrieving user's transaction history
    * Canceling scheduled transactions
2. Each transaction must include:
    * Sender and recipient
    * Amount and currency
    * Transaction status
    * Transaction type (immediate/scheduled)
    * Execution date (for scheduled transactions
3. Business Rules:
    * Transactions can be created in different currencies (minimum USD, EUR)
    * Scheduled transactions can be canceled before execution
    * Users cannot have negative balances
    * The system must properly handle concurrent transactions

#### Technical Requirements
1. Ruby on Rails application
2. Hotwire based UI
3. Tests for core functionality

### Important Considerations
1. Concurrent access to user balances
2. Error handling and edge cases
3. Transaction atomicity
4. Ability to add new currencies
5. Action logging

### Evaluation Criteria
1. Solution architecture
2. Edge case handling
3. Code and test quality
4. Documentation and explanation of design decisions
5. Understanding of scaling challenges

### Solution Expectations
We don't expect a perfectly complete product. We're more interested in seeing:
1. Your approach to system design
2. Ability to prioritize under time constraints
3. Understanding of trade-offs in your decisions
4. Understanding of Rails practices especially in the UI department

### Technical Notes
Consider these aspects in your solution:
1. Choice of locking mechanisms
2. Database structure
3. Currency handling
4. Scheduled transaction execution mechanism

## Installation and running via the  Docker

The application already has `Dockerfile` and `docker-compose.yml`. To run the application, run the following commands
in your terminal window:
```
docker-compose up

# After installation all dependencies:
docker-compose exec app rails db:create
docker-compose exec app rails db:migrate
docker-compose exec app rails db:seed
```

Since the application has been created via the asdf manager for the Ruby and PostgreSQL, you should change
the following folder for database host:
```
config/database.yml
development:
  <<: *default
  database: financial_transactions_app_development
  host: '/tmp' # CHANGE THIS !!!
```

## Installation and running manually

To run the application, do the following commands in your terminal window:

* Clone the repository from GitHub and navigate to the application folder:
```
git clone https://github.com/gwynolanga/financial_transactions_app.git
cd financial_transactions_app
```

* Install the necessary application gems specified in the `Gemfile`:
```
bundle install
```

* Create a database, run database migrations and the `seeds.rb` file to create database records:
```
# Run each command separately:
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
```

The application uses the `PostgreSQL` database for development/test environment and the `Postgresql` database for
production environment. Since the application has been created via the asdf manager for the Ruby and PostgreSQL,
you should change the following folder for database host:
```
config/database.yml
development:
  <<: *default
  database: financial_transactions_app_development
  host: '/tmp' # CHANGE THIS !!!
```

* Launch the application (local server):
```
bundle exec rails server
```
