# frozen_string_literal: true

##
# We run experiments with GitHub's Scientist library.
#

# Make sure our experiment class is loaded.
# This lets Scientist use it as "default".
require 'experiment'

# In candidate code, only rescue errors that normal applications can deal with.
Scientist::Observation::RESCUES.replace [StandardError]

# Raise errors when we have a mismatch in a test case.
# This helps with verifying comparison logic, and immediately fixing mismatches
# surfaced by test scenarios.
Experiment.raise_on_mismatches = true if Rails.env.test?
