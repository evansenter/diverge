#!/bin/sh
gem uninstall diverge --ignore-dependencies
gem build diverge.gemspec && gem install diverge --no-rdoc --no-ri --ignore-dependencies && ruby -e "require 'diverge'"
