#!/usr/bin/make -f

RAILS_ENV ?= development
BRANDS := xikolo $(shell find brand -mindepth 1 -maxdepth 1 -type d | xargs -n1 basename)

SPROCKET_TARGETS=$(BRANDS:%=sprockets/%)
WEBPACK_TARGETS=$(BRANDS:%=webpack/%)
I18N_TARGETS=$(BRANDS:%=i18n/%)

# The default assets target builds all assets for a single target. This
# can be invoked by a developer to build the webpack assets and the
# sprockets assets at once. This target is not brand-specific.
assets: webpack sprockets

install:
	corepack yarn install $(YARNFLAGS)

i18n:
	bundle exec rake assets:i18n:export

webpack: install i18n
	corepack yarn run build --mode $(RAILS_ENV) --stats-error-details

sprockets: install
	RAILS_ENV=$(RAILS_ENV) RAILS_GROUPS=assets bundle exec rake assets:precompile


# The following targets are tuned to compile all brands at once as done
# when packaging the application. They are not intended to be invoked
# individually.
all: all-webpack all-sprockets

all-i18n: $(I18N_TARGETS)
all-webpack: $(WEBPACK_TARGETS)
all-sprockets: $(SPROCKET_TARGETS)

$(I18N_TARGETS):
	BRAND=$(@F) bundle exec rake assets:i18n:export

$(SPROCKET_TARGETS): install
	RAILS_ENV=$(RAILS_ENV) RAILS_GROUPS=assets BRAND=$(@F) bundle exec rake assets:precompile

$(WEBPACK_TARGETS): install all-i18n
	corepack yarn run build --mode $(RAILS_ENV) --env BRAND=$(@F) --stats-error-details
