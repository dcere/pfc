require 'rubygems'
require 'sinatra'
require 'active_record'

class Article < ActiveRecord::Base
end

get '/' do
   'Hello there!'
end

