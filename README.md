# OkCupid Browser

A Ruby & Sinatra-based web application that improves the browsing experience to okcupid.com. Given a user name, fetch & display your matches.

To protect the identify of those profile users' the images have been blurred in the following screenshot. 
![screenshot of application running](http://i.imgur.com/WudUN.jpg)

## Requirements
* Sqlite3
* Ruby 1.8.7+

## Setup

Once you have these items install you can navigate to the /web directory and run the following commands. Please note, you can set SIN_VERBOSE to 1 or 2 which will output debug text. Setting SIN_VERBOSE to 2 outputs SQL queries.

```
bundle install --path=vendor
```

I prefer to use the path=vendor component to localize the rubygems dependencies.

```
bundle exec ruby lib/database.rb setup
```

This will create a new okcupid.db in the /db directory and then initialize it with the necessary tables that the
tool will use to store profile data for offline viewing.

Finally, you'll need to scrape some data from OkCupid to be able to view profiles. To do this, simply call:

```
OKNAME='ok_cupid_username' OKPASS='ok_user_password' bundle exec ruby lib/scraper.rb do_it_all
```
The above command will take a while to work as it goes and fetches ~200 profiles per run. You can modify this in the code if you want to pull more or less.
To view the results of the scraping you can launch the web app from the /web directory like so:

```
rackup
```

## Notes
We had initially placed a username/password blocker in the application so that you could theoretically
cron job the scraper and just leave this app thing running on your local machine and access the web
portion from the outside world. To do this, you'll notice we don't care what password you enter
as long as you provide a username that is permitted by the database. Small security. 
Enhance and submit a pull request :) !
  ...
To make life easier, when you run the scraper on a username it will auto-add that username
to the registered_users table. But, should you want to let other usernames browse the site
you should add those manually.

## Things to save for later

* ************ Facial Recognition Resources **************
* http://jeffkreeftmeijer.com/2011/comparing-images-and-creating-image-diffs/
* http://scikit-learn.org/stable/auto_examples/applications/face_recognition.html#example-applications-face-recognition-py
* http://libface.sourceforge.net/file/Features.html
* http://www.cs.ucsb.edu/~mturk/Papers/mturk-CVPR91.pdf
* http://cvdazzle.com/ AWESOME ONE
* http://creatingwithcode.com/howto/face-detection-in-static-images-with-python/

* ************** FACIAL APIS
* http://www.kooaba.com/en/home/developers
* http://www.betafaceapi.com/
* http://face.com/