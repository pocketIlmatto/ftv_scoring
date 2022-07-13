# https://www.socalxcleague.com/articles/ftv
FTV_PCT = 25

def read_task_validities
  task_validities = {}
  File.readlines('tasks', chomp: true).each do |line|
    task_validities = line.split(',').map { |x| x.to_f }
  end
  task_validities
end

def get_sum(array)
  array.inject(0){ |sum, x| sum + x }
end

def get_ftv(total_validity, ftv_pct)
  total_validity - total_validity * ftv_pct/100
end

def read_scores
  scores = []
  File.readlines('scores', chomp: true).each do |line|
    score = line.split(',')
    pilot = {}
    pilot[:pilot] = score[0]
    pilot[:raw_scores] = score[1..-1]
    scores << pilot
  end
  scores
end

def gen_sorted_performance_scores(scores, tasks)
  scores.each do |pilot_score|
    raw_scores = pilot_score[:raw_scores]
    perf_scores = []
    raw_scores.each_with_index do |raw, idx|
      task_validity = tasks[idx].to_f

      perf_scores << [idx, raw.to_f/task_validity]
    end
    perf_scores.sort_by! { |x| x[1] }.reverse!
    pilot_score[:perf_scores] = perf_scores
  end

  scores
end

def gen_ftv_scores(scores, ftv, tasks)
  scores.each do |pilot|
    pilot[:ftv_scores] = gen_pilot_ftv_score(pilot, ftv, tasks)
  end
  scores
end

def gen_pilot_ftv_score(pilot, ftv, tasks)
  remaining_validity = ftv
  ftv_scores = []

  pilot[:perf_scores].each do |perf_score|
    task_validity = tasks[perf_score[0]]
    raw_score = pilot[:raw_scores][perf_score[0]]

    if remaining_validity > task_validity
      ftv_scores << raw_score.to_f
      remaining_validity -= task_validity
    elsif remaining_validity > 0
      ftv_scores << raw_score.to_f * (remaining_validity/task_validity)
      remaining_validity = 0
    else
      remaining_validity = 0
      ftv_scores << 0
    end
  end
  ftv_scores
end

def gen_totals(scores)
  scores.each do |pilot|
    pilot[:raw_total] = get_sum(pilot[:raw_scores].map { |x| x.to_f })
    pilot[:ftv_total] = get_sum(pilot[:ftv_scores].map { |x| x.to_f })
  end
  scores
end

tasks = read_task_validities
total_validity = get_sum(tasks)
ftv = get_ftv(total_validity, FTV_PCT)
scores = read_scores
scores = gen_sorted_performance_scores(scores, tasks)
scores = gen_ftv_scores(scores, ftv, tasks)
scores = gen_totals(scores)
puts "Total validity: #{total_validity}"
puts "FTV: #{ftv}"
puts scores



