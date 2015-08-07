require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'
# get '/nest' do
#   erb :'users/user_template'
# end

BLACKJACK = 21
DEALER_MIN = 17
SUITS = ['Hearts', 'Diamonds', 'Spades', 'Clubs']
RANKS = ['Ace', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven',
         'Eight', 'Nine', 'Ten', 'Jack', 'Queen', 'King']

helpers do
  def initialize_deck
    SUITS.each_with_object([]) do |suit, deck|
      RANKS.each_with_index do |rank, index|
        value = index > 9 ? 10 : index + 1
          deck << {rank: rank, suit: suit, value: value}
      end
    end
  end

  def card_image_id(card)
    case card[:rank]
    when 'Ace' then 'ace'
    when 'Two' then '2'
    when 'Three' then '3'
    when 'Four' then '4'
    when 'Five' then '5'
    when 'Six' then '6'
    when 'Seven' then '7'
    when 'Eight' then '8'
    when 'Nine' then '9'
    when 'Ten' then '10'
    when 'Jack' then 'jack'
    when 'Queen' then 'queen'
    when 'King' then 'king'
    end
  end

  def card_image_string(card)
    suit = card[:suit].downcase
    id = card_image_id(card)
    "<img src='/images/cards/#{suit}_#{id}.jpg' style='border: 2px solid black; border-radius: 5px'/>"
  end

  def hit(player)
    session[:player_hand] << session[:deck].shift if player == 'human'
    session[:dealer_hand] << session[:deck].shift if player == 'dealer'
  end



end

get '/' do
  redirect '/welcome'
end

get '/welcome' do
  erb :welcome
end

get '/instructions' do
  erb :instructions
end

post '/start_new_game' do
  session[:player_name] = params[:player_name].capitalize
  session[:deck] = initialize_deck
  session[:discard_pile] = []
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:player_money] = 100
  session[:deck].shuffle!
  redirect '/begin'
end

get '/begin' do
  hit('human')
  hit('dealer')
  @player_card_image = card_image_string(session[:player_hand][0])
  @dealer_card_image = card_image_string(session[:dealer_hand][0])
  erb :begin
end

post '/set_bet' do
  session[:player_bet] = params[:player_bet]
  session[:player_money] -= session[:player_bet].to_i
  hit('human')
  hit('dealer')
  redirect '/game'
end

get '/game' do
  @player_hand_images = session[:player_hand].each_with_object([]) do |card, images|
    images << card_image_string(card)
  end
  @dealer_card_image = card_image_string(session[:dealer_hand][0])
  erb :game
end
