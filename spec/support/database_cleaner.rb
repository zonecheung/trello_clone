RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    if example.metadata[:skip_db_cleaner]
      example.run
    else
      DatabaseCleaner.cleaning do
        example.run
      end
    end
  end
end
