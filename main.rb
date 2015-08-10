require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

BLACKJACK = 21
DEALER_MIN = 17
SUITS = ['Hearts', 'Diamonds', 'Spades', 'Clubs']
RANKS = ['Ace', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven',
         'Eight', 'Nine', 'Ten', 'Jack', 'Queen', 'King']
VALIDATION_STRING = "Oops! Looks like your input was invalid. Please try again."

helpers do
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
    "<img src='/images/cards/#{suit}_#{id}.jpg' class='card'/>"
  end

  def card_images(hand)
    if hand == player_hand
      @player_hand_images = player_hand.map { |card| card_image_string (card) }
    elsif dealer_plays?
      @dealer_hand_images = dealer_hand.map { |card| card_image_string(card) }
    else
      @dealer_hand_images = [card_image_string(dealer_hand[0]), "<img src='/images/cards/cover.jpg' class='card'/>"]
    end
  end

  def welcome_button
    "<form action='/welcome'>
      <button class='btn btn-danger'>Start A New Game!</button>
    </form>"
  end

  def place_bet_button
    "<form action='/place_bet'>
      <button class='btn btn-danger'>Place your bet!</button>
    </form>"
  end

  def game_button
    "<form action='/game'>
      <button class='btn btn-danger'>Continue!</button>
    </form>"
  end

  def results_string
    string = ''
    if player_wins?
      string = "You win!"
      if blackjack?(player_hand)
        string.prepend("You got blackjack! ")
      elsif bust?(dealer_hand)
        string.prepend("The dealer bust! ")
      else
        string.prepend("The dealer stayed at #{hand_total(dealer_hand)} and you stayed at #{hand_total(player_hand)}. ")
      end
    elsif dealer_wins?
      string = "You lose!"
      if bust?(player_hand)
        string.prepend("You busted! ")
      elsif blackjack?(dealer_hand)
        string.prepend("The dealer got blackjack. ")
      else
        string.prepend("The dealer stayed at #{hand_total(dealer_hand)} and you stayed at #{hand_total(player_hand)}. ")
      end
    else
      string = "It's a tie!"
    end
    string
  end

  def play_again!(string)
    if player_has_money?
      string += " You've amassed $#{session[:player_money]}. Do you want to start another round? "
    else
      string += " Looks like you've run out of money. Start a new game, if you like."
    end
    string
  end

  def results_alert
    alert_type = ''
    alert_type = '-success' if player_wins?
    alert_type = '-error' if dealer_wins?
    if player_has_money?
      "<div class='alert span12 alert#{alert_type}'>
        <h3 id='results_string'>#{play_again!(results_string)}</h3>
        <form class='player_action' action='/start_new_round'>
          <button class='btn btn-danger'>Let's keep going!</button>
        </form>
      </div>"
    else
      "<div class='alert span12 alert#{alert_type}'>
        <h3>#{play_again!(results_string)}</h3>
      </div>"
    end
  end

  def player_hand
    session[:player_hand]
  end

  def dealer_hand
    session[:dealer_hand]
  end

  def player_has_money?
    session[:player_money] > 0
  end

  def initialize_deck
    SUITS.each_with_object([]) do |suit, deck|
      RANKS.each_with_index do |rank, index|
        value = index > 9 ? 10 : index + 1
        deck << {rank: rank, suit: suit, value: value}
      end
    end
  end

  def number_of_aces(hand)
    hand.select {|card| card[:rank] == 'Ace'}.count
  end

  def hand_total(hand)
    total = 0
    aces = number_of_aces(hand)
    hand.each do |card|
      next if card[:rank] == 'Ace'
      total += card[:value]
    end
    if aces > 0
      total += aces if (total + 10 + aces > BLACKJACK) || (total + aces >= BLACKJACK)
      total += 10 + aces if (total + 10 + aces <= BLACKJACK)
    end
    total
  end

  def blackjack?(hand)
    hand_total(hand) == BLACKJACK
  end

  def first_turn_blackjack?
    player_hand.count == 2 && blackjack?(player_hand)
  end

  def bust?(hand)
    hand_total(hand) > BLACKJACK
  end

  def hit(hand)
    hand << session[:deck].shift
  end

  def player_turn_over?
    session[:stay] || blackjack?(player_hand) || bust?(player_hand)
  end

  def dealer_plays?
    player_turn_over? && !first_turn_blackjack? && !bust?(player_hand)
  end

  def dealer_turn_over?
    return true unless dealer_plays?
    hand_total(dealer_hand) >= DEALER_MIN
  end

  def dealer_hits?
    dealer_plays? && !dealer_turn_over?
  end

  def round_over?
    player_turn_over? && dealer_turn_over?
  end

  def winner
    if first_turn_blackjack? || (!bust?(player_hand) &&
          hand_total(player_hand) > hand_total(dealer_hand)) ||  (!bust?(player_hand) && bust?(dealer_hand))
      "player"
    elsif (hand_total(player_hand) == hand_total(dealer_hand))
      'tie'
    else
      'dealer'
    end
  end

  def player_wins?
    winner == "player"
  end

  def dealer_wins?
    winner == 'dealer'
  end

  def discard_hands
    [player_hand, dealer_hand].each do |hand|
      session[:discard_pile] += hand
      hand.clear
    end
    session[:discard_pile].flatten!
  end

  def replenish_deck
    session[:deck] += session[:discard_pile]
    session[:discard_pile].clear
  end

  def fetch_and_update_game_state
    if round_over? && player_wins? && !session[:player_settled]
     session[:player_money] += session[:player_bet]
     session[:player_settled] = true
    elsif round_over? && dealer_wins? && !session[:player_settled]
     session[:player_money] -= session[:player_bet]
     session[:player_settled] = true
    end
    card_images(player_hand)
    card_images(dealer_hand)
    @hit_dealer_button = true if dealer_hits?
    @result = results_alert if round_over?
  end

end

get '/' do
  redirect '/welcome'
end

get '/welcome' do
  session.clear
  erb :welcome
end

post '/set_name' do
  session[:player_name] = params[:player_name].capitalize
  redirect '/start_new_game'
end

get '/start_new_game' do
  if [nil, '', ' '].include?(session[:player_name])
    session[:invalid_input] = true
    @error = VALIDATION_STRING
    halt erb :welcome
  end
  session[:deck] = initialize_deck
  session[:deck].shuffle!
  session[:discard_pile] = []
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:player_money] = 500
  redirect '/start_new_round'
end

get '/start_new_round' do
  discard_hands
  replenish_deck if session[:deck].count < 27
  session[:deck].shuffle!
  session[:player_bet] = 0
  session[:player_settled] = false
  session[:stay] = false
  2.times do
    hit(player_hand)
    hit(dealer_hand)
  end
  redirect '/place_bet'
end

get '/place_bet' do
  erb :place_bet
end

post '/place_bet' do
  session[:player_bet] = params[:player_bet].to_i
  unless session[:player_bet].between?(1, session[:player_money])
    @error = VALIDATION_STRING
    halt erb :place_bet
  end
  redirect '/game'
end

get '/game' do
  fetch_and_update_game_state
  erb :game
end

post '/game/stay' do
  session[:stay] = true
  fetch_and_update_game_state
  erb :game, layout: false
end

post '/game/hit_player' do
  hit(player_hand)
  fetch_and_update_game_state
  erb :game, layout: false
end

post '/game/hit_dealer' do
  hit(dealer_hand)
  fetch_and_update_game_state
  erb :game, layout: false
end

get '/help' do
  if session[:player_name]
    @button = session[:player_bet] > 0 ? game_button : place_bet_button
  else
    @button = welcome_button
  end
  erb :help
end
