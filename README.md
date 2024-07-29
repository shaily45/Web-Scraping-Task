# YCombinator Scraper

## Description
This is a Rails project using Ruby version 2.7.8. The project setup includes bundling gems and setting up the database.

## Setup

1. **Install Ruby 2.7.8**

	If you are using RVM, you can install and use Ruby 2.7.8 with the following commands:
	```sh
	rvm install 2.7.8
	rvm use 2.7.8
	```

2. **Install Gems**

	Run the following command to install the necessary gems:
	```sh
	  bundle install
	```

3. **Set Up the Database**

	Run the following command to set up the database:
	```sh
	rails db:setup
	```

4. **Precompile Assets**
   
  Run the following command:
  ```sh
  rails assets:precompile
  ```

5. **Start the Rails server**

	To start the Rails server, use the following command:
  ```sh
  rails server
  ```

6. **To provide input for the scraper, you can use a JSON structure like the following:**

  ```json
  {
	  "n": 5,
	  "filters": {
	    "batch": "W21",
	    "industry": "Healthcare",
	    "is_hiring": true
	  }
	}
	```
