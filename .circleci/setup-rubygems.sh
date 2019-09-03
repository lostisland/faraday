
#
# "Publishing RubyGems using Circle CI 2.0" explains how this works:
#
# https://medium.com/@pezholio/publishing-rubygems-using-circle-ci-2-0-1dbf06ae9942
#
# - Get an API key from your profile page at RubyGems.org
# - Add the API key as an Environment variable in your repo’s CircleCI
#   Project Settings/Build Settings/Environment Variables
# - Have this script execute in the deploy stage of the CI build
# - Now you can "gem push"

mkdir ~/.gem
echo -e "---\r\n:rubygems_api_key: $RUBYGEMS_API_KEY" > ~/.gem/credentials
chmod 0600 /home/circleci/.gem/credentials
