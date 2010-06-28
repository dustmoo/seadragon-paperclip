Info
-----

This is a processor for the rails gem paperclip: http://github.com/thoughtbot/paperclip and is used according to their processor guidelines. with png support.
This processor also require the RMagic gem http://github.com/rmagick/rmagick

This processor takes an image uploaded by paperclip and processes it into tiles for the Seadragon Ajax Library: http://www.seadragon.com/developer/ajax/

The assumption is that you are familiar with installing and setting up Seadragon. If not, please check out the documentation at the above URL.


License
-----

This is released under the MIT License which only applies to this code and not RMagic or Paperclip, which are dependancies of this code.
Coded by Dustin Moore, dustin@discoverymap.com

The MIT License

Copyright (c) 2010 Starr Map Company LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


Installation
------------

This is a processor for the Paperclip gem. Before you do anything install Paperclip and RMagic on your server.

Read the comments in the code. I used this tile library to store tiles on Amazon S3 but commented out S3 specific code.

To install place this in your /libs/paperclip_processors directory under your Rails project.

In your Seadragon Object, you call the paperclip processor like so:

		has_attached_file :seadragon_art, :styles => { :tiled => [{:style => "tiled"}, :xml]},
		:processors => [:tile_art],
		:path => ":attachment/:id/:style/:filename"
		
If you are using S3 it would look something like this:

		has_attached_file :seadragon_art, :styles => { :tiled => [{:style => "tiled"}, :xml]},
		:processors => [:tile_art],
		:storage => :s3,
		:s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
		:path => ":attachment/:id/:style/:filename"
		
		
Then from your Rails views, just setup Seadragon to look for the XML and Images in your rails path.

Changelog
---------

6-28-2010

* Commented and pushed to git.



