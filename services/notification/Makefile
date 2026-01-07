#!/usr/bin/make -f

RAILS_ENV ?= development

# The default assets target builds all assets for a single target. This
# can be invoked by a developer to build the webpack assets and the
# sprockets assets at once. This target is not brand-specific.
assets: sprockets

sprockets:
	RAILS_ENV=$(RAILS_ENV) RAILS_GROUPS=assets bundle exec rake assets:precompile


# The following targets are tuned to compile all brands at once as done
# when packaging the application. They are not intended to be invoked
# individually.
all: all-sprockets

all-sprockets: $(SPROCKET_TARGETS)

$(SPROCKET_TARGETS):
	RAILS_ENV=$(RAILS_ENV) RAILS_GROUPS=assets bundle exec rake assets:precompile
