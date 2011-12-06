#!/usr/bin/env ruby

require 'quiz'

def question(text)
  Quiz.instance.add_question Question.new(text)
end

def right(text)
  Quiz.instance.last_question.add_answer Answer.new(text,true)
end

def wrong(text)
  Quiz.instance.last_question.add_answer Answer.new(text,false)
end

load 'questions.qm'

Quiz.instance.run_quiz

