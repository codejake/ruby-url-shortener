require 'sinatra'
require 'sqlite3'
require 'securerandom'

# Prepare the SQLite database
DB = SQLite3::Database.new "mydb.sqlite"
DB.execute <<-SQL
  CREATE TABLE IF NOT EXISTS urls (
    id INTEGER PRIMARY KEY,
    url TEXT,
    random_number TEXT,
    date_created TEXT,
    date_modified TEXT
  );
SQL

# Sinatra routes
get '/' do
  # Query to fetch the last 25 submitted URLs
  @urls = DB.execute "SELECT url, random_number FROM urls ORDER BY id DESC LIMIT 25"

  erb :form
end

post '/submit' do
  url = params[:tbURL]
  random_number = SecureRandom.random_number(36**8).to_s(36)
  current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")

  DB.execute "INSERT INTO urls (url, random_number, date_created, date_modified) VALUES (?, ?, ?, ?)",
             [url, random_number, current_time, current_time]

  @url = url
  @random_number = random_number

  erb :submitted
end


# New route to handle /l/<random_number>
get '/l/:random_number' do
    random_number = params[:random_number]
  
    # Query the database for the URL
    url_row = DB.execute "SELECT url FROM urls WHERE random_number = ?", [random_number]
  
    # Redirect to the URL if found, else display an error
    if url_row.any?
      redirect url_row.first.first
    else
      "URL not found."
    end
  end

# Embedded Ruby template for the form
__END__

@@form
<!DOCTYPE html>
<html>
<head>
  <title>URL Input</title>
</head>
<body>
  <form action="/submit" method="post">
    <label for="tbURL">Enter URL:</label>
    <input type="url" id="tbURL" name="tbURL" required 
      pattern="https://.*" placeholder="https://www.google.com">
    <input type="submit" value="Submit">
  </form>

  <h2>Last 100 Submitted URLs</h2>
  <table border="1">
    <tr>
      <th>URL</th>
      <th>Random Number</th>
    </tr>
    <% @urls.each do |url, random_number| %>
      <tr>
        <td><%= url %></td>
        <td><a href="/l/<%= random_number %>"><%= random_number %></a></td>
      </tr>
    <% end %>
  </table>
</body>
</html>

@@submitted
<!DOCTYPE html>
<html>
<head>
  <title>URL Submitted</title>
</head>
<body>
  <p>URL <a href="<%= @url %>"><%= @url %></a> saved with random number: 
  <a href="/l/<%= @random_number %>"><%= @random_number %></a></p>
</body>
</html>