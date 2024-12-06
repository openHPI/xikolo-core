# Grouping Service

This services assigns users to certain groups using assignment rules.
Currently this restricts to A/B-Testing.

## Documentation

Can be found in `doc/api`.

## Recalculate

```ruby
Trial.where(user_test_id: '19b95430-a573-4dec-a0cc-2c288952aa37').each do |t|
  t.update(:finished => true)
  t.trial_results.each do |r|
    r.update(:result => nil)
    TrialResultWorker.perform_async r.id
  end
end

```

Assure we have a metric

```ruby
user_test = UserTest.find('19b95430-a573-4dec-a0cc-2c288952aa37')
user_test.trials.each do |trial|
  user_test.metrics.each do |metric|
    trial.trial_results.find_or_create_by metric: metric
  end
end
```
