require 'singleton'

class Quiz
  include Singleton

  def initialize
    @questions = []
  end

  def add_question(question)
    @questions << question
  end

  def last_question
    @questions.last
  end

  def run_quiz
    count=0
    @questions.each { |q| count += 1 if q.ask }
    puts "You got #{count} answers correct out of #{@questions.size}."
  end
end


class Question

  def initialize(text)
    @text = text
    @answers = []
  end

  def add_answer(answer)
    @answers << answer
  end

  def ask
    puts ""
    puts "Question: #{@text}"
    @answers.size.times do |i|
      puts "#{i+1} - #{@answers[i].text}"
    end
    print "Enter answer: "
    answer = gets.to_i - 1
    return @answers[answer].correct
  end
end


class Answer
  attr_reader :text, :correct
  def initialize(text, correct)
    @text = text
    @correct = correct
  end
end

