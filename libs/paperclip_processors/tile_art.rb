#Code for Tiler from http://blog.aisleten.com/2007/08/25/attachment_fu-s3-ruby-tile-cutter-google-maps-easy-custom-maps-in-ruby-on-rails/
#Taken from his modified tiler and then modified! :D Thanks for thie inspiration!


#This is released under the MIT License which only applies to this code and not RMagic or Paperclip, which are dependancies of this code.
# Coded by Dustin Moore, dustin@discoverymap.com
#
#The MIT License
#
#Copyright (c) 2010 Starr Map Company LLC
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

#This is a processor for the rails gem paperclip: http://github.com/thoughtbot/paperclip and is used according to their processor guidelines. with png support.
#This processor also require the RMagic gem http://github.com/rmagick/rmagick



module Paperclip
  class TileArt < Processor
    attr_accessor :whiny
    require 'RMagick'
    
    def initialize(file, options = {}, attachment = nil)
      
      super
      #Object is the parent object of the image attachment in this case the paperclip attachment is in a SeadragonImage object. This is so we can get it's id to set path names
      @object = attachment.instance
      @tile_size = 256
      @max_width = Paperclip::Geometry.from_file(file).width 
      @max_height = Paperclip::Geometry.from_file(file).height 
      @whiny = options[:whiny].nil? ? true : options[:whiny]
      @basename = File.basename(attachment.path, File.extname(attachment.path))
      @tmpname = File.basename(file.path, File.extname(file.path))
      
      @max_level = get_max_level(@max_width, @max_height)
    end
    
    def make
      info = Tempfile.new([ @tmpname, 'xml' ].compact.join("."))
      
      level = @max_level
      @width = @max_width
      @height = @max_height
      
      #This sets up the XML string for Seadragon to store in the location of the files.
      tile_xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?><Image TileSize=\"256\" Overlap=\"1\" Format=\"png\" ServerFormat=\"Default\" xmlns=\"http://schemas.microsoft.com/deepzoom/2009\"><Size Width=\""+@max_width.to_s+"\" Height=\""+@max_height.to_s+"\" /></Image>"
      info << tile_xml
      #I store my xml string in my Seadragon Object make sure you ad tile_xml to your model or comment this out.
      @object.tile_xml = tile_xml
      
      #Convert the original upload to a tmp ping to tile from.
      convert_from_path = File.expand_path(file.path)
      file_name = "tmp.png"
      
      #Begin Tile Processing
      while level >= 0
        if @width < 256 || @height < 256
          file_name = "0_0.png"
        end
        
        columns = (@width/@tile_size).ceil
        rows = (@height/@tile_size).ceil
        
        #The base path of where you want to store your tiles, I use system to prevent development/production conflicts with capistrano deployment.        
        local_base_path = "#{RAILS_ROOT}/public/system/arts/"+@object.id.to_s+"/"+options[:geometry][:style]+"/#{@basename}_files"
        
        #Do not change tilepath, it writes the tile filenames in the way Seadragon likes.
        tile_path = local_base_path +"/"+level.to_s #+"/"+columns.to_s+"_"+rows.to_s+".png"attachment.path.gsub(/\.[a-z][a-z][a-z]$/, "")
        tile_file_path = tile_path+"/"+file_name
        
        FileUtils.mkdir_p(tile_path)
        
        unless @max_width == @width || @max_height == @height        
          cmd = "-flatten "+convert_from_path+" -resize "+@width.to_s+"x"+@height.to_s+"\\> "+tile_file_path
        else
          cmd = "-flatten "+convert_from_path+" "+tile_file_path
        end
        
        begin
          Paperclip.run("convert", cmd)
        rescue PaperclipCommandLineError
          raise PaperclipError, "There was an error processing the tiles for #{@basename}" if whiny
        end
        
        #S3 processing
        #connect_to_S3
        
        
        image_to_tile = Magick::ImageList.new(tile_file_path)
        (0..columns).each do |c|
          x = (c * 256) 
          (0..rows).each do |r|
            y = (r * 256)
            tile = image_to_tile.crop(x, y, 258, 258)
            tile_file_name = c.to_s+"_"+r.to_s+".png"
            write_path = tile_path +"/"+tile_file_name
            #Uncomment for S3 storage, set the s3 path to how you want it stored on Se
            # s3_path = "arts/"+@object.id.to_s+"/"+options[:geometry][:style]+"/#{@basename}_files/"+level.to_s+"/"+tile_file_name
            tile.write(write_path)
            # AWS::S3::S3Object.store(s3_path, open(write_path), "smcwidget",{:access => :public_read }.update(options))
            tile_info = Tile.new(:path => s3_path)
            @object.tiles << tile_info
          end
        end
                
        
        
        #We convert from our converted thumbs to reduce processing time
        convert_from_path = tile_file_path
        @width = (@width/2).ceil
        @height = (@height/2).ceil
        level = level - 1
        
      end
      
      #Uncomment if using S3 to Remove Local Tiles after processing is done. 
      # FileUtils.remove_entry_secure(local_base_path, true)
      info.rewind
      # This is the processor output, which in this case is actually the XML file, the tiles are written by RMagick.
      info
    end
    
    #Math to determine how many levels of tiles we need to make.
    def get_max_level(width, height)
      h = [width, height]
      max = h.max
      level = log_with_base(2, max).ceil
      return level
    end
    
    
    #Setup log with base for max level function
    def log_with_base(base, num)
        Math.log(num) / Math.log(base)
    end
    
    #If you want to store your tiles on S3.
    
    def connect_to_S3
      unless AWS::S3::Base.connected?
        AWS::S3::Base.establish_connection!(:access_key_id => 'yourkey', :secret_access_key => 'youraccesskey')
      end
    end
    
  end
end
